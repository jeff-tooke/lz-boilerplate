locals {
  # Common tags applied to all resources
  common_tags = merge(
    var.tags,
    {
      Environment   = var.environment
      ManagedBy     = "terraform"
      Module        = "terraform-state"
      ModuleVersion = local.module_version
      Purpose       = "terraform-state-backend"
    }
  )

  # Resource naming
  bucket_name         = var.bucket_suffix != "" ? "${var.name}-terraform-state-${var.bucket_suffix}" : "${var.name}-terraform-state"
  dr_bucket_name      = var.bucket_suffix != "" ? "${var.name}-terraform-state-${var.bucket_suffix}-dr" : "${var.name}-terraform-state-dr"
  dynamodb_table_name = var.dynamodb_table_name != "" ? var.dynamodb_table_name : "${var.name}-terraform-locks"

  # Logging bucket name (only used if creating new logging bucket)
  logging_bucket_name = "${var.name}-terraform-state-logs"

  # Current AWS account ID (for bucket policies)
  account_id = data.aws_caller_identity.current.account_id
}

data "aws_caller_identity" "current" {}
