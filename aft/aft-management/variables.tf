################################################################################
# Control Tower / AFT Account IDs
################################################################################

variable "ct_management_account_id" {
  description = "AWS account ID of the Control Tower management (root) account"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.ct_management_account_id))
    error_message = "Must be a valid 12-digit AWS account ID."
  }
}

variable "log_archive_account_id" {
  description = "AWS account ID of the Control Tower Log Archive account"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.log_archive_account_id))
    error_message = "Must be a valid 12-digit AWS account ID."
  }
}

variable "audit_account_id" {
  description = "AWS account ID of the Control Tower Audit account"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.audit_account_id))
    error_message = "Must be a valid 12-digit AWS account ID."
  }
}

variable "aft_management_account_id" {
  description = "AWS account ID where AFT is deployed (lives in the control-plane OU)"
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.aft_management_account_id))
    error_message = "Must be a valid 12-digit AWS account ID."
  }
}

################################################################################
# VCS Configuration (Azure DevOps — AFT >= 1.18.0 native support)
################################################################################

variable "account_request_repo_name" {
  description = "Name of the AFT account-request repo in Azure DevOps"
  type        = string
  default     = "severntrent/aws/account-request"
}

variable "global_customizations_repo_name" {
  description = "Name of the AFT global-customizations repo in Azure DevOps"
  type        = string
  default     = "severntrent/aws/global-customisations"
}

variable "account_customizations_repo_name" {
  description = "Name of the AFT account-customizations repo in Azure DevOps"
  type        = string
  default     = "severntrent/aws/account-customisations"
}

variable "account_provisioning_customizations_repo_name" {
  description = "Name of the AFT account-provisioning-customizations repo in Azure DevOps"
  type        = string
  default     = "severntrent/aws/account-customisations"
}

variable "default_repo_branch" {
  description = "Default git branch for all AFT repos"
  type        = string
  default     = "main"
}

################################################################################
# AFT Feature Flags
################################################################################

variable "aft_feature_cloudtrail_data_events" {
  description = "Enable AFT CloudTrail data event logging (additional cost)"
  type        = bool
  default     = false
}

variable "aft_feature_enterprise_support" {
  description = "Enable AFT enterprise support features"
  type        = bool
  default     = false
}

################################################################################
# Tagging
################################################################################

variable "tags" {
  description = "Additional tags to apply to AFT management resources"
  type        = map(string)
  default     = {}
}
