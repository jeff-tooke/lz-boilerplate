output "exec_role_name" {
  description = "Name of the Terraform execution role"
  value       = aws_iam_role.terraform_execution.name
}

output "exec_role_arn" {
  description = "ARN of the Terraform execution role"
  value       = aws_iam_role.terraform_execution.arn
}

output "kms_key_arn" {
  description = "ARN of the account KMS key"
  value       = aws_kms_key.account.arn
}

output "kms_key_id" {
  description = "ID of the account KMS key"
  value       = aws_kms_key.account.key_id
}

output "backup_kms_key_arn" {
  description = "ARN of the dedicated backup KMS key"
  value       = aws_kms_key.backup.arn
}

output "backup_kms_key_id" {
  description = "ID of the dedicated backup KMS key"
  value       = aws_kms_key.backup.key_id
}

output "state_bucket_name" {
  description = "Name of the Terraform state S3 bucket"
  value       = aws_s3_bucket.state.id
}

output "dynamodb_table_name" {
  description = "Name of the Terraform state lock DynamoDB table"
  value       = aws_dynamodb_table.locks.name
}

output "backup_vault_name" {
  description = "Name of the primary AWS Backup vault"
  value       = aws_backup_vault.primary.name
}

output "backup_vault_arn" {
  description = "ARN of the primary AWS Backup vault"
  value       = aws_backup_vault.primary.arn
}

output "backup_dr_enabled" {
  description = "Whether a DR backup vault was provisioned"
  value       = local.backup_dr_enabled
}

output "dr_backup_vault_arn" {
  description = "ARN of the DR backup vault (null if not provisioned)"
  value       = local.backup_dr_enabled ? aws_backup_vault.dr[0].arn : null
}

output "backup_longterm_enabled" {
  description = "Whether a long-term backup vault was provisioned"
  value       = local.backup_longterm_enabled
}

output "longterm_backup_vault_arn" {
  description = "ARN of the long-term backup vault (null if not provisioned)"
  value       = local.backup_longterm_enabled ? aws_backup_vault.longterm[0].arn : null
}

output "backup_plan_arn" {
  description = "ARN of the backup plan"
  value       = aws_backup_plan.main.arn
}
