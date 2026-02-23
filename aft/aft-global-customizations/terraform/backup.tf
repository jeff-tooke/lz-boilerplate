################################################################################
# AWS Backup Vault — Primary Region
#
# Created in all vended accounts. The Standard account customisation creates
# backup plans and selections that target this vault.
################################################################################

resource "aws_backup_vault" "primary" {
  name        = local.backup_vault_name
  kms_key_arn = aws_kms_key.backup.arn

  tags = merge(
    local.common_tags,
    {
      Name   = local.backup_vault_name
      Region = "primary"
    }
  )

  depends_on = [aws_kms_key.backup]
}

################################################################################
# Vault Lock — Primary Vault
#
# Compliance lock (t1/t2): immutable after the 3-day cooling-off period —
# even AWS Support cannot remove it.
# Governance lock (t3): can be removed by sufficiently privileged IAM users.
################################################################################

resource "aws_backup_vault_lock_configuration" "primary_compliance" {
  count = local.backup_compliance_lock ? 1 : 0

  backup_vault_name   = aws_backup_vault.primary.name
  changeable_for_days = 3
  min_retention_days  = 1
  max_retention_days  = 36500
}

resource "aws_backup_vault_lock_configuration" "primary_governance" {
  count = local.backup_governance_lock ? 1 : 0

  backup_vault_name  = aws_backup_vault.primary.name
  min_retention_days = 1
  max_retention_days = 36500
}

################################################################################
# Backup DR KMS Key (DR Region)
#
# Standalone regional KMS key in the DR region for encrypting the DR backup
# vault. Uses the same policy pattern as the primary backup key — scoped to
# backup.amazonaws.com — but is an independent key (not a replica).
################################################################################

resource "aws_kms_key" "backup_dr" {
  count    = local.backup_dr_enabled ? 1 : 0
  provider = aws.dr

  description             = "Backup KMS key DR - ${local.account_name} (${local.environment})"
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
      Name   = local.dr_backup_kms_alias
      Region = "dr"
    }
  )
}

resource "aws_kms_alias" "backup_dr" {
  count    = local.backup_dr_enabled ? 1 : 0
  provider = aws.dr

  name          = "alias/${local.dr_backup_kms_alias}"
  target_key_id = aws_kms_key.backup_dr[0].key_id
}

################################################################################
# Backup Vault — DR Region (t1-t3)
################################################################################

resource "aws_backup_vault" "dr" {
  count    = local.backup_dr_enabled ? 1 : 0
  provider = aws.dr

  name        = local.dr_backup_vault_name
  kms_key_arn = aws_kms_key.backup_dr[0].arn

  tags = merge(
    local.common_tags,
    {
      Name   = local.dr_backup_vault_name
      Region = "dr"
    }
  )

  depends_on = [aws_kms_key.backup_dr]
}

resource "aws_backup_vault_lock_configuration" "dr_compliance" {
  count    = local.backup_compliance_lock ? 1 : 0
  provider = aws.dr

  backup_vault_name   = aws_backup_vault.dr[0].name
  changeable_for_days = 3
  min_retention_days  = 1
  max_retention_days  = 36500
}

resource "aws_backup_vault_lock_configuration" "dr_governance" {
  count    = local.backup_governance_lock ? 1 : 0
  provider = aws.dr

  backup_vault_name  = aws_backup_vault.dr[0].name
  min_retention_days = 1
  max_retention_days = 36500
}

################################################################################
# Long-term Backup Vault — Primary Region (t1/t2 only)
#
# Monthly backups with 365-day retention. Compliance-locked so that
# long-term recovery points cannot be deleted before their expiry.
################################################################################

resource "aws_backup_vault" "longterm" {
  count = local.backup_longterm_enabled ? 1 : 0

  name        = local.backup_longterm_vault_name
  kms_key_arn = aws_kms_key.backup.arn

  tags = merge(
    local.common_tags,
    {
      Name    = local.backup_longterm_vault_name
      Purpose = "longterm-retention"
    }
  )
}

resource "aws_backup_vault_lock_configuration" "longterm_compliance" {
  count = local.backup_longterm_enabled ? 1 : 0

  backup_vault_name   = aws_backup_vault.longterm[0].name
  changeable_for_days = 3
  min_retention_days  = 365
  max_retention_days  = 36500
}

################################################################################
# IAM Role for AWS Backup Service
################################################################################

resource "aws_iam_role" "backup" {
  name        = local.backup_role_name
  description = "Role used by AWS Backup to create and restore backups"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = local.backup_role_name
    }
  )
}

resource "aws_iam_role_policy_attachment" "backup_backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

################################################################################
# Backup Plan — Tier-Based Schedule
#
# Primary rule: always created, schedule depends on business_criticality tier.
#   t1 = hourly, t2 = every 4h, t3/t4 = daily 03:00 UTC
#   28-day retention; cross-region copy to DR vault for t1-t3.
#
# Monthly long-term rule (t1/t2 only):
#   Runs on the 1st of each month at 03:00 UTC.
#   365-day retention in the long-term vault; also copied to DR vault.
################################################################################

resource "aws_backup_plan" "main" {
  name = local.backup_plan_name

  rule {
    rule_name         = "primary-rule"
    target_vault_name = local.backup_vault_name
    schedule          = local.backup_schedule
    start_window      = 60
    completion_window = 180

    lifecycle {
      delete_after = 28
    }

    dynamic "copy_action" {
      for_each = local.backup_dr_enabled ? [1] : []
      content {
        destination_vault_arn = aws_backup_vault.dr[0].arn

        lifecycle {
          delete_after = 28
        }
      }
    }
  }

  dynamic "rule" {
    for_each = local.backup_longterm_enabled ? [1] : []
    content {
      rule_name         = "monthly-longterm"
      target_vault_name = aws_backup_vault.longterm[0].name
      schedule          = "cron(0 3 1 * ? *)"
      start_window      = 60
      completion_window = 180

      lifecycle {
        delete_after = 365
      }

      copy_action {
        destination_vault_arn = aws_backup_vault.dr[0].arn

        lifecycle {
          delete_after = 365
        }
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.backup_plan_name
    }
  )
}

################################################################################
# Backup Selection — Tag-Based Opt-In
# Resources tagged backup = "true" are protected by the backup plan above.
################################################################################

resource "aws_backup_selection" "tagged" {
  name         = local.backup_selection_name
  plan_id      = aws_backup_plan.main.id
  iam_role_arn = aws_iam_role.backup.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "backup"
    value = "true"
  }
}
