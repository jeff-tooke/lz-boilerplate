################################################################################
# Example: Terraform State Backend with Cross-Region Replication
################################################################################

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }

  # NOTE: This example creates the state backend infrastructure.
  # You cannot use the backend it creates until AFTER the first apply.
  # Initial apply must use local state, then migrate to remote.
}

provider "aws" {
  region = "eu-west-1"
}

################################################################################
# State Backend with DR
################################################################################

module "terraform_state" {
  source = "../"

  name           = "mycompany"
  environment    = "shared"
  primary_region = "eu-west-1"

  # Enable cross-region replication for resilience
  dr_enabled = true
  dr_region  = "eu-west-2"

  # Bucket configuration
  force_destroy      = false # NEVER enable in production
  versioning_enabled = true

  # Lifecycle rules
  lifecycle_rules = {
    enabled                       = true
    noncurrent_version_expiration = 90 # Keep 90 days of state history
    abort_incomplete_upload_days  = 7
  }

  # DynamoDB configuration (Global Table for DR)
  dynamodb_billing_mode           = "PAY_PER_REQUEST"
  dynamodb_point_in_time_recovery = true

  # Encryption
  kms_key_deletion_window = 30
  kms_enable_key_rotation = true

  # Access logging for audit trail
  access_logging_enabled = true
  access_logging_prefix  = "state-access-logs/"

  # Cross-account access (if needed)
  # allowed_account_ids = ["111111111111", "222222222222"]

  tags = {
    Project   = "platform"
    Owner     = "platform-team"
    Terraform = "true"
  }
}

################################################################################
# Outputs
################################################################################

output "state_bucket" {
  description = "Primary state bucket details"
  value = {
    id     = module.terraform_state.state_bucket_id
    arn    = module.terraform_state.state_bucket_arn
    region = module.terraform_state.state_bucket_region
  }
}

output "dr_state_bucket" {
  description = "DR state bucket details"
  value = {
    id     = module.terraform_state.dr_state_bucket_id
    arn    = module.terraform_state.dr_state_bucket_arn
    region = module.terraform_state.dr_state_bucket_region
  }
}

output "dynamodb_table" {
  description = "DynamoDB lock table (global table)"
  value = {
    name = module.terraform_state.dynamodb_table_name
    arn  = module.terraform_state.dynamodb_table_arn
  }
}

output "backend_config" {
  description = "Backend configuration for both regions"
  value = {
    primary = module.terraform_state.backend_config_primary
    dr      = module.terraform_state.backend_config_dr
  }
}

# Write backend config files for easy use
resource "local_file" "backend_primary" {
  content  = module.terraform_state.backend_hcl_primary
  filename = "${path.module}/generated/backend-primary.hcl"
}

resource "local_file" "backend_dr" {
  count    = module.terraform_state.replication_enabled ? 1 : 0
  content  = module.terraform_state.backend_hcl_dr
  filename = "${path.module}/generated/backend-dr.hcl"
}

output "usage_instructions" {
  description = "How to use the generated backend configurations"
  value       = <<-EOT

    ============================================================
    TERRAFORM STATE BACKEND SETUP COMPLETE
    ============================================================

    Backend configuration files have been generated:
    - Primary: ./generated/backend-primary.hcl
    - DR:      ./generated/backend-dr.hcl

    INITIAL SETUP (for new projects):
    ---------------------------------
    1. Add this to your terraform configuration:

       terraform {
         backend "s3" {}
       }

    2. Initialize with primary backend:

       terraform init -backend-config=path/to/backend-primary.hcl

    FAILOVER PROCEDURE (during primary region outage):
    --------------------------------------------------
    1. Attempt to access primary (may timeout):

       terraform init -backend-config=backend-primary.hcl

    2. If primary fails, switch to DR backend:

       terraform init -backend-config=backend-dr.hcl -reconfigure

    3. Continue operations against DR backend

    IMPORTANT NOTES:
    ----------------
    - State replication has up to 15 minutes lag
    - DynamoDB Global Table provides automatic lock failover
    - After failover, verify state consistency before making changes
    - Do NOT write to both backends simultaneously

    ============================================================
  EOT
}
