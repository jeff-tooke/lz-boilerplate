################################################################################
# KMS Key for State Encryption (Primary Region)
################################################################################

resource "aws_kms_key" "state" {
  description             = "KMS key for Terraform state encryption - ${var.name}"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = var.kms_enable_key_rotation
  multi_region            = var.dr_enabled

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Sid    = "EnableRootAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowS3ServiceEncryption"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
      ],
      length(var.allowed_account_ids) > 0 ? [
        {
          Sid    = "AllowCrossAccountAccess"
          Effect = "Allow"
          Principal = {
            AWS = [for id in var.allowed_account_ids : "arn:aws:iam::${id}:root"]
          }
          Action = [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ]
          Resource = "*"
        }
    ] : [])
  })

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-terraform-state-key"
      Region = "primary"
    }
  )
}

resource "aws_kms_alias" "state" {
  name          = "alias/${var.name}-terraform-state"
  target_key_id = aws_kms_key.state.key_id
}

################################################################################
# S3 Bucket for Terraform State (Primary Region)
################################################################################

resource "aws_s3_bucket" "state" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    local.common_tags,
    {
      Name   = local.bucket_name
      Region = "primary"
    }
  )
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status     = var.versioning_enabled ? "Enabled" : "Suspended"
    mfa_delete = var.mfa_delete_enabled ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.state.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "state" {
  count  = var.lifecycle_rules.enabled ? 1 : 0
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = var.lifecycle_rules.noncurrent_version_expiration
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = var.lifecycle_rules.abort_incomplete_upload_days
    }
  }
}

################################################################################
# S3 Bucket Policy (Primary Region)
################################################################################

resource "aws_s3_bucket_policy" "state" {
  bucket = aws_s3_bucket.state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Sid       = "EnforceTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.state.arn,
          "${aws_s3_bucket.state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid       = "EnforceEncryption"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.state.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      {
        Sid       = "DenyIncorrectKMSKey"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.state.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption-aws-kms-key-id" = aws_kms_key.state.arn
          }
        }
      }
      ],
      length(var.allowed_account_ids) > 0 ? [
        {
          Sid    = "AllowCrossAccountAccess"
          Effect = "Allow"
          Principal = {
            AWS = [for id in var.allowed_account_ids : "arn:aws:iam::${id}:root"]
          }
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:DeleteObject",
            "s3:ListBucket",
            "s3:GetBucketLocation"
          ]
          Resource = [
            aws_s3_bucket.state.arn,
            "${aws_s3_bucket.state.arn}/*"
          ]
        }
      ] : [],
      length(var.denied_ip_ranges) > 0 ? [
        {
          Sid       = "DenySpecificIPs"
          Effect    = "Deny"
          Principal = "*"
          Action    = "s3:*"
          Resource = [
            aws_s3_bucket.state.arn,
            "${aws_s3_bucket.state.arn}/*"
          ]
          Condition = {
            IpAddress = {
              "aws:SourceIp" = var.denied_ip_ranges
            }
          }
        }
    ] : [])
  })

  depends_on = [aws_s3_bucket_public_access_block.state]
}

################################################################################
# Access Logging Bucket (Primary Region)
################################################################################

resource "aws_s3_bucket" "logging" {
  count = var.access_logging_enabled && var.access_logging_bucket == "" ? 1 : 0

  bucket        = local.logging_bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    local.common_tags,
    {
      Name    = local.logging_bucket_name
      Purpose = "s3-access-logging"
    }
  )
}

resource "aws_s3_bucket_versioning" "logging" {
  count  = var.access_logging_enabled && var.access_logging_bucket == "" ? 1 : 0
  bucket = aws_s3_bucket.logging[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logging" {
  count  = var.access_logging_enabled && var.access_logging_bucket == "" ? 1 : 0
  bucket = aws_s3_bucket.logging[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logging" {
  count  = var.access_logging_enabled && var.access_logging_bucket == "" ? 1 : 0
  bucket = aws_s3_bucket.logging[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logging" {
  count  = var.access_logging_enabled && var.access_logging_bucket == "" ? 1 : 0
  bucket = aws_s3_bucket.logging[0].id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    expiration {
      days = 365
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}

# Grant S3 logging service permission to write to the bucket
resource "aws_s3_bucket_policy" "logging" {
  count  = var.access_logging_enabled && var.access_logging_bucket == "" ? 1 : 0
  bucket = aws_s3_bucket.logging[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ServerAccessLogsPolicy"
        Effect = "Allow"
        Principal = {
          Service = "logging.s3.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.logging[0].arn}/*"
        Condition = {
          ArnLike = {
            "aws:SourceArn" = aws_s3_bucket.state.arn
          }
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
        }
      },
      {
        Sid       = "EnforceTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.logging[0].arn,
          "${aws_s3_bucket.logging[0].arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.logging]
}

# Enable logging on state bucket
resource "aws_s3_bucket_logging" "state" {
  count  = var.access_logging_enabled ? 1 : 0
  bucket = aws_s3_bucket.state.id

  target_bucket = var.access_logging_bucket != "" ? var.access_logging_bucket : aws_s3_bucket.logging[0].id
  target_prefix = var.access_logging_prefix
}

################################################################################
# DynamoDB Table for State Locking (Global Table)
################################################################################

resource "aws_dynamodb_table" "locks" {
  name             = local.dynamodb_table_name
  billing_mode     = var.dynamodb_billing_mode
  hash_key         = "LockID"
  stream_enabled   = var.dr_enabled
  stream_view_type = var.dr_enabled ? "NEW_AND_OLD_IMAGES" : null

  # Only set capacity if PROVISIONED billing mode
  read_capacity  = var.dynamodb_billing_mode == "PROVISIONED" ? var.dynamodb_read_capacity : null
  write_capacity = var.dynamodb_billing_mode == "PROVISIONED" ? var.dynamodb_write_capacity : null

  attribute {
    name = "LockID"
    type = "S"
  }

  point_in_time_recovery {
    enabled = var.dynamodb_point_in_time_recovery
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.state.arn
  }

  # Create replica in DR region for Global Table
  dynamic "replica" {
    for_each = var.dr_enabled ? [var.dr_region] : []
    content {
      region_name            = replica.value
      kms_key_arn            = aws_kms_replica_key.state_dr[0].arn
      point_in_time_recovery = var.dynamodb_point_in_time_recovery
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.dynamodb_table_name
    }
  )

  # Ensure DR KMS key exists before creating replica
  depends_on = [aws_kms_replica_key.state_dr]
}
