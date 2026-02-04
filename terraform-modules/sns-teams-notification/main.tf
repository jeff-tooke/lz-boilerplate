data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  # Build the Teams Adaptive Card template
  teams_card_template = jsonencode({
    type = "message"
    attachments = [
      {
        contentType = "application/vnd.microsoft.card.adaptive"
        content = {
          "$schema" = "http://adaptivecards.io/schemas/adaptive-card.json"
          type      = "AdaptiveCard"
          version   = "1.4"
          msteams = {
            width = "Full"
          }
          body = [
            {
              type   = "TextBlock"
              text   = "<$.body.subject>"
              weight = "Bolder"
              size   = "Large"
              wrap   = true
            },
            {
              type = "TextBlock"
              text = "<$.body.message>"
              wrap = true
            },
            {
              type = "FactSet"
              facts = [
                { title = "Event Type", value = "<$.body.event_type>" },
                { title = "Source", value = "<$.body.source>" },
                { title = "Timestamp", value = "<$.time>" }
              ]
            }
          ]
        }
      }
    ]
  })
}

# SNS Topic
resource "aws_sns_topic" "this" {
  name              = var.name
  kms_master_key_id = var.kms_key_arn
  tags              = var.tags
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "this" {
  arn    = aws_sns_topic.this.arn
  policy = data.aws_iam_policy_document.sns_topic_policy.json
}

data "aws_iam_policy_document" "sns_topic_policy" {
  statement {
    sid    = "AllowPublish"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "cloudwatch.amazonaws.com"]
    }
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.this.arn]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

# EventBridge Connection (required for API Destination, even without auth)
resource "aws_cloudwatch_event_connection" "teams" {
  name               = "${var.name}-teams-connection"
  description        = "Connection to Microsoft Teams webhook"
  authorization_type = "API_KEY"

  auth_parameters {
    api_key {
      key   = "X-Dummy-Auth"
      value = "not-used"
    }
  }
}

# EventBridge API Destination
resource "aws_cloudwatch_event_api_destination" "teams" {
  name                             = "${var.name}-teams"
  description                      = "Microsoft Teams webhook destination"
  invocation_endpoint              = var.teams_webhook_url
  http_method                      = "POST"
  invocation_rate_limit_per_second = var.rate_limit_per_second
  connection_arn                   = aws_cloudwatch_event_connection.teams.arn
}

# IAM Role for EventBridge Pipes
resource "aws_iam_role" "pipe" {
  name = "${var.name}-pipe-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "pipes.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "pipe_source" {
  name = "${var.name}-pipe-source"
  role = aws_iam_role.pipe.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [aws_sqs_queue.pipe_source.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy" "pipe_target" {
  name = "${var.name}-pipe-target"
  role = aws_iam_role.pipe.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "events:InvokeApiDestination"
        ]
        Resource = [aws_cloudwatch_event_api_destination.teams.arn]
      }
    ]
  })
}

# SQS Queue as pipe source (EventBridge Pipes requires SQS/Kinesis/DynamoDB as source, not SNS directly)
resource "aws_sqs_queue" "pipe_source" {
  name                       = "${var.name}-pipe-source"
  visibility_timeout_seconds = 60
  message_retention_seconds  = 86400
  kms_master_key_id          = var.kms_key_arn

  tags = var.tags
}

resource "aws_sqs_queue_policy" "pipe_source" {
  queue_url = aws_sqs_queue.pipe_source.id
  policy    = data.aws_iam_policy_document.sqs_policy.json
}

data "aws_iam_policy_document" "sqs_policy" {
  statement {
    sid    = "AllowSNS"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.pipe_source.arn]
    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.this.arn]
    }
  }
}

# SNS to SQS Subscription
resource "aws_sns_topic_subscription" "sqs" {
  topic_arn            = aws_sns_topic.this.arn
  protocol             = "sqs"
  endpoint             = aws_sqs_queue.pipe_source.arn
  raw_message_delivery = true
}

# EventBridge Pipe
resource "aws_pipes_pipe" "sns_to_teams" {
  name     = "${var.name}-to-teams"
  role_arn = aws_iam_role.pipe.arn
  source   = aws_sqs_queue.pipe_source.arn
  target   = aws_cloudwatch_event_api_destination.teams.arn

  source_parameters {
    sqs_queue_parameters {
      batch_size                         = 1
      maximum_batching_window_in_seconds = 0
    }
  }

  target_parameters {
    http_parameters {
      header_parameters = {
        "Content-Type" = "application/json"
      }
    }

    input_template = local.teams_card_template
  }

  tags = var.tags
}
