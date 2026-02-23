################################################################################
# SSM Output Parameters
#
# These parameters are written to the vended account's SSM Parameter Store
# so the Standard account customisation layer can reference global resources
# without reconstructing names or making additional API calls.
################################################################################

resource "aws_ssm_parameter" "exec_role_name" {
  name        = "/aft/output/exec-role-name"
  description = "Name of the Terraform execution role created by global customisations"
  type        = "String"
  value       = aws_iam_role.terraform_execution.name

  tags = local.common_tags
}

resource "aws_ssm_parameter" "kms_key_arn" {
  name        = "/aft/output/kms-key-arn"
  description = "ARN of the account KMS key"
  type        = "String"
  value       = aws_kms_key.account.arn

  tags = local.common_tags
}

resource "aws_ssm_parameter" "backup_kms_key_arn" {
  name        = "/aft/output/backup-kms-key-arn"
  description = "ARN of the dedicated backup KMS key"
  type        = "String"
  value       = aws_kms_key.backup.arn

  tags = local.common_tags
}

resource "aws_ssm_parameter" "backup_vault_name" {
  name        = "/aft/output/backup-vault-name"
  description = "Name of the primary AWS Backup vault"
  type        = "String"
  value       = aws_backup_vault.primary.name

  tags = local.common_tags
}

resource "aws_ssm_parameter" "state_bucket_name" {
  name        = "/aft/output/state-bucket-name"
  description = "Name of the Terraform state S3 bucket"
  type        = "String"
  value       = aws_s3_bucket.state.id

  tags = local.common_tags
}

resource "aws_ssm_parameter" "dynamodb_table_name" {
  name        = "/aft/output/dynamodb-table-name"
  description = "Name of the Terraform state lock DynamoDB table"
  type        = "String"
  value       = aws_dynamodb_table.locks.name

  tags = local.common_tags
}
