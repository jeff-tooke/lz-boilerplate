################################################################################
# Account KMS Key (Primary Region)
#
# A single regional KMS key used for general account encryption:
#   - S3 Terraform state bucket
#   - DynamoDB state lock table
#
# Policy grants the root account full access; further access is delegated via
# IAM policies rather than additional key policy statements.
################################################################################

resource "aws_kms_key" "account" {
  description             = "Account KMS key - ${local.account_name} (${local.environment})"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${local.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name   = "${local.name_prefix}-kms"
      Region = "primary"
    }
  )
}

resource "aws_kms_alias" "account" {
  name          = "alias/${local.kms_key_alias}"
  target_key_id = aws_kms_key.account.key_id
}

################################################################################
# Backup KMS Key (Primary Region)
#
# Dedicated KMS key scoped exclusively to AWS Backup encryption.
# Keeping it separate from the account key ensures that backup service access
# is granted narrowly without widening the general-purpose key policy.
################################################################################

resource "aws_kms_key" "backup" {
  description             = "Backup KMS key - ${local.account_name} (${local.environment})"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
        Sid    = "AllowBackupEncryption"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name   = "${local.name_prefix}-backup-kms"
      Region = "primary"
    }
  )
}

resource "aws_kms_alias" "backup" {
  name          = "alias/${local.backup_kms_key_alias}"
  target_key_id = aws_kms_key.backup.key_id
}
