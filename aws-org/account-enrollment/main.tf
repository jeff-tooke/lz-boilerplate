data "aws_caller_identity" "current" {}
data "aws_organizations_organization" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  org_id     = data.aws_organizations_organization.current.id
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_sqs_queue" "dlq" {
  name                      = "control-tower-auto-enroll-dlq"
  message_retention_seconds = 1209600 # 14 days
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/control-tower-auto-enroll"
  retention_in_days = 180 # 6 months
}

resource "aws_sns_topic" "dlq_alerts" {
  name = "control-tower-enroll-failures"
}

resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "control-tower-enroll-dlq-messages"
  alarm_description   = "Alert when Control Tower enrollment Lambda failures are in the DLQ"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }

  alarm_actions = [aws_sns_topic.dlq_alerts.arn]
  ok_actions    = [aws_sns_topic.dlq_alerts.arn]
}

resource "aws_iam_role" "ct_enroll_lambda_role" {
  name = "ControlTowerEnrollLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ct_enroll_lambda_policy" {
  name = "ControlTowerEnrollLambdaPolicy"
  role = aws_iam_role.ct_enroll_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "controltower:EnrollAccount",
          "controltower:ListAccounts"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "organizations:DescribeAccount",
          "organizations:ListTagsForResource",
          "organizations:ListParents"
        ]
        Resource = "arn:aws:organizations::${local.account_id}:account/${local.org_id}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "organizations:ListRoots"
        ]
        Resource = "arn:aws:organizations::${local.account_id}:root/${local.org_id}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:${local.account_id}:log-group:/aws/lambda/control-tower-auto-enroll:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.dlq.arn
      }
    ]
  })
}

resource "aws_lambda_function" "ct_enroll" {
  function_name = "control-tower-auto-enroll"
  role          = aws_iam_role.ct_enroll_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 300

  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256

  dead_letter_config {
    target_arn = aws_sqs_queue.dlq.arn
  }

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
}

resource "aws_cloudwatch_event_rule" "org_create_account" {
  name = "org-create-account"

  event_pattern = jsonencode({
    source = ["aws.organizations"],
    "detail-type" = ["AWS API Call via CloudTrail"],
    detail = {
      eventSource = ["organizations.amazonaws.com"]
      eventName   = ["CreateAccount"]
    }
  })
}

resource "aws_cloudwatch_event_target" "ct_enroll_target" {
  rule      = aws_cloudwatch_event_rule.org_create_account.name
  target_id = "ControlTowerEnrollLambda"
  arn       = aws_lambda_function.ct_enroll.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ct_enroll.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.org_create_account.arn
}

output "sns_topic_arn" {
  description = "SNS topic ARN for DLQ alerts - subscribe to receive failure notifications"
  value       = aws_sns_topic.dlq_alerts.arn
}

output "dlq_url" {
  description = "SQS DLQ URL - check here for failed enrollment events"
  value       = aws_sqs_queue.dlq.url
}
