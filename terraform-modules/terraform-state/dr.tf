################################################################################
# DR Region Provider
################################################################################

provider "aws" {
  alias  = "dr"
  region = var.dr_region
}

################################################################################
# KMS Replica Key (DR Region)
################################################################################

resource "aws_kms_replica_key" "state_dr" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr

  description             = "KMS replica key for Terraform state encryption - ${var.name} (DR)"
  primary_key_arn         = aws_kms_key.state.arn
  deletion_window_in_days = var.kms_key_deletion_window

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
      Name   = "${var.name}-terraform-state-key-dr"
      Region = "dr"
    }
  )
}

resource "aws_kms_alias" "state_dr" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr

  name          = "alias/${var.name}-terraform-state-dr"
  target_key_id = aws_kms_replica_key.state_dr[0].key_id
}

################################################################################
# S3 Bucket for Terraform State (DR Region)
################################################################################

resource "aws_s3_bucket" "state_dr" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr

  bucket        = local.dr_bucket_name
  force_destroy = var.force_destroy

  tags = merge(
    local.common_tags,
    {
      Name   = local.dr_bucket_name
      Region = "dr"
    }
  )
}

resource "aws_s3_bucket_versioning" "state_dr" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.state_dr[0].id

  versioning_configuration {
    status     = "Enabled" # Required for replication destination
    mfa_delete = var.mfa_delete_enabled ? "Enabled" : "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_dr" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.state_dr[0].id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_replica_key.state_dr[0].arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "state_dr" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.state_dr[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "state_dr" {
  count    = var.dr_enabled && var.lifecycle_rules.enabled ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.state_dr[0].id

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
# S3 Bucket Policy (DR Region)
################################################################################

resource "aws_s3_bucket_policy" "state_dr" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr
  bucket   = aws_s3_bucket.state_dr[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Sid       = "EnforceTLS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.state_dr[0].arn,
          "${aws_s3_bucket.state_dr[0].arn}/*"
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
        Resource  = "${aws_s3_bucket.state_dr[0].arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
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
            aws_s3_bucket.state_dr[0].arn,
            "${aws_s3_bucket.state_dr[0].arn}/*"
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
            aws_s3_bucket.state_dr[0].arn,
            "${aws_s3_bucket.state_dr[0].arn}/*"
          ]
          Condition = {
            IpAddress = {
              "aws:SourceIp" = var.denied_ip_ranges
            }
          }
        }
    ] : [])
  })

  depends_on = [aws_s3_bucket_public_access_block.state_dr]
}

################################################################################
# IAM Role for S3 Replication
################################################################################

resource "aws_iam_role" "replication" {
  count = var.dr_enabled ? 1 : 0

  name = "${var.name}-terraform-state-replication"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-terraform-state-replication"
    }
  )
}

resource "aws_iam_role_policy" "replication" {
  count = var.dr_enabled ? 1 : 0

  name = "${var.name}-terraform-state-replication"
  role = aws_iam_role.replication[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.state.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.state.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${aws_s3_bucket.state_dr[0].arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = aws_kms_key.state.arn
        Condition = {
          StringEquals = {
            "kms:ViaService" = "s3.${var.primary_region}.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_replica_key.state_dr[0].arn
        Condition = {
          StringEquals = {
            "kms:ViaService" = "s3.${var.dr_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

################################################################################
# S3 Cross-Region Replication Configuration
################################################################################

resource "aws_s3_bucket_replication_configuration" "state" {
  count = var.dr_enabled ? 1 : 0

  bucket = aws_s3_bucket.state.id
  role   = aws_iam_role.replication[0].arn

  rule {
    id     = "replicate-state-to-dr"
    status = "Enabled"

    filter {
      prefix = ""
    }

    destination {
      bucket        = aws_s3_bucket.state_dr[0].arn
      storage_class = "STANDARD"

      encryption_configuration {
        replica_kms_key_id = aws_kms_replica_key.state_dr[0].arn
      }

      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }

      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.state,
    aws_s3_bucket_versioning.state_dr
  ]
}
