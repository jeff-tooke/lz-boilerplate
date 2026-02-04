################################################################################
# General Configuration
################################################################################

variable "name" {
  description = "Name prefix for state resources (e.g., 'mycompany' creates 'mycompany-terraform-state')"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., prod, nonprod). Used for tagging and resource naming."
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Primary Region Configuration
################################################################################

variable "primary_region" {
  description = "Primary AWS region for the state bucket"
  type        = string
}

################################################################################
# DR Region Configuration
################################################################################

variable "dr_enabled" {
  description = "Enable cross-region replication to DR region for state resilience"
  type        = bool
  default     = true
}

variable "dr_region" {
  description = "DR region for state replication (required if dr_enabled is true)"
  type        = string
  default     = ""
}

################################################################################
# S3 Bucket Configuration
################################################################################

variable "bucket_suffix" {
  description = "Suffix for the S3 bucket name. Full name will be: {name}-terraform-state-{suffix}"
  type        = string
  default     = ""
}

variable "force_destroy" {
  description = "Allow destruction of non-empty state buckets. WARNING: Set to false in production!"
  type        = bool
  default     = false
}

variable "versioning_enabled" {
  description = "Enable versioning on state buckets (strongly recommended)"
  type        = bool
  default     = true
}

variable "mfa_delete_enabled" {
  description = "Enable MFA delete on state buckets (requires versioning)"
  type        = bool
  default     = false
}

variable "lifecycle_rules" {
  description = "Lifecycle rules for state bucket"
  type = object({
    enabled                       = bool
    noncurrent_version_expiration = number
    abort_incomplete_upload_days  = number
  })
  default = {
    enabled                       = true
    noncurrent_version_expiration = 90
    abort_incomplete_upload_days  = 7
  }
}

################################################################################
# DynamoDB Configuration
################################################################################

variable "dynamodb_table_name" {
  description = "Name for the DynamoDB lock table. Defaults to '{name}-terraform-locks'"
  type        = string
  default     = ""
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode: PAY_PER_REQUEST or PROVISIONED"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.dynamodb_billing_mode)
    error_message = "Billing mode must be PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "dynamodb_read_capacity" {
  description = "Read capacity units (only used if billing_mode is PROVISIONED)"
  type        = number
  default     = 5
}

variable "dynamodb_write_capacity" {
  description = "Write capacity units (only used if billing_mode is PROVISIONED)"
  type        = number
  default     = 5
}

variable "dynamodb_point_in_time_recovery" {
  description = "Enable point-in-time recovery for DynamoDB table"
  type        = bool
  default     = true
}

################################################################################
# Encryption Configuration
################################################################################

variable "kms_key_deletion_window" {
  description = "KMS key deletion window in days (7-30)"
  type        = number
  default     = 30

  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "KMS key deletion window must be between 7 and 30 days."
  }
}

variable "kms_enable_key_rotation" {
  description = "Enable automatic KMS key rotation"
  type        = bool
  default     = true
}

################################################################################
# Access Configuration
################################################################################

variable "allowed_account_ids" {
  description = "List of AWS account IDs allowed to access the state bucket (for cross-account access)"
  type        = list(string)
  default     = []
}

variable "denied_ip_ranges" {
  description = "List of IP CIDR ranges to explicitly deny access (e.g., for compliance)"
  type        = list(string)
  default     = []
}

################################################################################
# Logging Configuration
################################################################################

variable "access_logging_enabled" {
  description = "Enable S3 access logging for audit trail"
  type        = bool
  default     = true
}

variable "access_logging_bucket" {
  description = "Existing S3 bucket for access logs. If empty, a new bucket is created."
  type        = string
  default     = ""
}

variable "access_logging_prefix" {
  description = "Prefix for access log objects"
  type        = string
  default     = "terraform-state-logs/"
}
