################################################################################
# Module Version
################################################################################

output "module_version" {
  description = "Version of the terraform-state module"
  value       = local.module_version
}

################################################################################
# Primary Region Outputs
################################################################################

output "state_bucket_id" {
  description = "ID of the primary state bucket"
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  description = "ARN of the primary state bucket"
  value       = aws_s3_bucket.state.arn
}

output "state_bucket_region" {
  description = "Region of the primary state bucket"
  value       = var.primary_region
}

output "kms_key_id" {
  description = "ID of the primary KMS key"
  value       = aws_kms_key.state.key_id
}

output "kms_key_arn" {
  description = "ARN of the primary KMS key"
  value       = aws_kms_key.state.arn
}

output "kms_key_alias" {
  description = "Alias of the primary KMS key"
  value       = aws_kms_alias.state.name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB lock table"
  value       = aws_dynamodb_table.locks.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB lock table"
  value       = aws_dynamodb_table.locks.arn
}

output "logging_bucket_id" {
  description = "ID of the logging bucket (if created)"
  value       = var.access_logging_enabled && var.access_logging_bucket == "" ? aws_s3_bucket.logging[0].id : null
}

################################################################################
# DR Region Outputs
################################################################################

output "dr_state_bucket_id" {
  description = "ID of the DR state bucket (null if DR not enabled)"
  value       = var.dr_enabled ? aws_s3_bucket.state_dr[0].id : null
}

output "dr_state_bucket_arn" {
  description = "ARN of the DR state bucket (null if DR not enabled)"
  value       = var.dr_enabled ? aws_s3_bucket.state_dr[0].arn : null
}

output "dr_state_bucket_region" {
  description = "Region of the DR state bucket (null if DR not enabled)"
  value       = var.dr_enabled ? var.dr_region : null
}

output "dr_kms_key_id" {
  description = "ID of the DR KMS replica key (null if DR not enabled)"
  value       = var.dr_enabled ? aws_kms_replica_key.state_dr[0].key_id : null
}

output "dr_kms_key_arn" {
  description = "ARN of the DR KMS replica key (null if DR not enabled)"
  value       = var.dr_enabled ? aws_kms_replica_key.state_dr[0].arn : null
}

output "replication_role_arn" {
  description = "ARN of the replication IAM role (null if DR not enabled)"
  value       = var.dr_enabled ? aws_iam_role.replication[0].arn : null
}

################################################################################
# Backend Configuration Outputs
################################################################################

output "backend_config_primary" {
  description = "Terraform backend configuration for primary region"
  value = {
    bucket         = aws_s3_bucket.state.id
    region         = var.primary_region
    encrypt        = true
    kms_key_id     = aws_kms_key.state.arn
    dynamodb_table = aws_dynamodb_table.locks.name
  }
}

output "backend_config_dr" {
  description = "Terraform backend configuration for DR region (null if DR not enabled)"
  value = var.dr_enabled ? {
    bucket         = aws_s3_bucket.state_dr[0].id
    region         = var.dr_region
    encrypt        = true
    kms_key_id     = aws_kms_replica_key.state_dr[0].arn
    dynamodb_table = aws_dynamodb_table.locks.name # Same global table
  } : null
}

################################################################################
# Backend Configuration Files (HCL format)
################################################################################

output "backend_hcl_primary" {
  description = "Terraform backend configuration in HCL format for primary region"
  value       = <<-EOT
    bucket         = "${aws_s3_bucket.state.id}"
    region         = "${var.primary_region}"
    encrypt        = true
    kms_key_id     = "${aws_kms_key.state.arn}"
    dynamodb_table = "${aws_dynamodb_table.locks.name}"
  EOT
}

output "backend_hcl_dr" {
  description = "Terraform backend configuration in HCL format for DR region"
  value = var.dr_enabled ? <<-EOT
    bucket         = "${aws_s3_bucket.state_dr[0].id}"
    region         = "${var.dr_region}"
    encrypt        = true
    kms_key_id     = "${aws_kms_replica_key.state_dr[0].arn}"
    dynamodb_table = "${aws_dynamodb_table.locks.name}"
  EOT
  : null
}

################################################################################
# Replication Status
################################################################################

output "replication_enabled" {
  description = "Whether cross-region replication is enabled"
  value       = var.dr_enabled
}

output "replication_metrics_enabled" {
  description = "Whether replication metrics are enabled (always true when DR enabled)"
  value       = var.dr_enabled
}
