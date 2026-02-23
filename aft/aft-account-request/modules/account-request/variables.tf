################################################################################
# Account Identity
################################################################################

variable "svc_name" {
  description = "Service or workload slug for this account (e.g. 'payments', 'scada', 'log-archive'). Do not include the system_domain prefix or environment — those are combined automatically to form the AWS account name: <domain_prefix>-<svc_name>-<environment>. Must be unique within the organisation for the given domain and environment combination."
  type        = string
}

variable "account_email" {
  description = "Root email address for the account. Must be globally unique."
  type        = string
}

variable "account_description" {
  description = "Human-readable description of the account's purpose"
  type        = string
  default     = ""
}

################################################################################
# Placement
################################################################################

variable "ou_name" {
  description = "Target OU path as shown in Control Tower (e.g. 'Root/infrastructure/it-prod'). Verify against the CT console — hyphens vs underscores matter."
  type        = string
}

################################################################################
# AFT Customisation Hook
################################################################################

variable "account_customizations_name" {
  description = "Name of the account customisation set to apply. Must match a directory under aft-account-customizations/."
  type        = string
  default     = "Standard"
}

################################################################################
# Governance — mirrored as both account_tags (on the AWS account) and
# custom_fields (written to SSM in the vended account for use by Terraform)
################################################################################

variable "environment" {
  description = "Lifecycle environment for the account. Used in resource naming and tagging. IT/OT prod accounts go to their respective prod OUs; dev/test/pre-prod go to nonprod OUs."
  type        = string

  validation {
    condition     = contains(["dev", "test", "pre-prod", "prod", "sandbox"], var.environment)
    error_message = "Must be one of: dev, test, pre-prod, prod, sandbox."
  }
}

variable "system_domain" {
  description = "System domain that owns the account. 'it' for IT workloads and shared services (resource prefix: st-); 'ot' for OT workloads (resource prefix: ot-). Drives OU placement and enforces strong isolation for ot accounts."
  type        = string

  validation {
    condition     = contains(["it", "ot"], var.system_domain)
    error_message = "Must be one of: it, ot."
  }
}

variable "business_criticality" {
  description = "Business criticality tier for the account (t0 = highest, t4 = lowest). Drives automation decisions: t1–t3 enable backup DR replication to eu-west-1. t0 is reserved for core infrastructure accounts that carry no persistent data — recovery is via IaC rather than backup DR."
  type = string

  validation {
    condition     = contains(["t0", "t1", "t2", "t3", "t4"], var.business_criticality)
    error_message = "Must be one of: t0, t1, t2, t3, t4."
  }

  validation {
    condition     = !(var.environment == "prod" && var.business_criticality == "t4")
    error_message = "Production accounts cannot use business_criticality = \"t4\". Assign t1, t2, or t3 for production workloads."
  }
}

variable "business_unit" {
  description = "Business unit that owns the account. Used for tagging only — does not affect resource naming or OU placement. Defaults to 'infrastructure'."
  type        = string
  default     = "infrastructure"
}

variable "service_name" {
  description = "Human-readable service or workload name for the account_tags ServiceName tag. Defaults to '<domain_prefix>-<svc_name>-<environment>' if not provided."
  type        = string
  default     = ""
}

################################################################################
# Tagging
################################################################################

variable "tags" {
  description = "Additional tags to apply to the vended account"
  type        = map(string)
  default     = {}
}
