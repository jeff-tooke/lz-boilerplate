variable "name_prefix" {
  description = "Prefix for all resource names, e.g. 'it' or 'ot'"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name_prefix))
    error_message = "name_prefix must be lowercase alphanumeric and hyphens only."
  }
}

variable "internal_cidr" {
  description = "Primary internal CIDR for this domain's network"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.internal_cidr))
    error_message = "internal_cidr must be a valid CIDR block."
  }
}

variable "dr_internal_cidr" {
  description = "DR internal CIDR for this domain's network"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.dr_internal_cidr))
    error_message = "internal_cidr must be a valid CIDR block."
  }
}
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ---------------------------------------------------------------
# Egress
# ---------------------------------------------------------------
variable "allowed_egress_domains" {
  description = <<-EOT
    List of domains permitted for internet egress via TLS_SNI and HTTP_HOST
    inspection. Each entry should be prefixed with a dot to match subdomains,
    e.g. ".github.com". No default — must be explicitly set per system domain.
  EOT
  type        = list(string)
  default     = []
}

# ---------------------------------------------------------------
# East-West AD
# ---------------------------------------------------------------
variable "enable_ad_rules" {
  description = <<-EOT
    Include AD/DC port rules for east-west (VPC-to-VPC) traffic.
    Enable when Domain Controllers are deployed within the AWS network
    service auth requests across VPCs.
    NOTE: When hardening, remove the broad east-west pass rules at the
    same time as enabling these — do not run both simultaneously.
  EOT
  type        = bool
  default     = false
}

# ---------------------------------------------------------------
# On-premises
# ---------------------------------------------------------------
variable "onprem_cidr" {
  description = "On-premises CIDR block. Required when enable_onprem_inspection = true."
  type        = string
  default     = null

  validation {
    condition     = var.onprem_cidr == null || can(cidrnetmask(var.onprem_cidr))
    error_message = "onprem_cidr must be a valid CIDR block or null."
  }
}

variable "enable_onprem_inspection" {
  description = <<-EOT
    Create and attach the on-premises stateful rule group. Requires onprem_cidr
    to be set. Also enables the corresponding stateless forward rules for
    on-prem sourced traffic — without these, on-prem traffic is dropped at
    the stateless layer before reaching the stateful engine.
  EOT
  type        = bool
  default     = false
}

variable "enable_onprem_ad_rules" {
  description = <<-EOT
    Include AD/DC port rules in the on-prem stateful rule group. Enable when
    Domain Controllers in AWS and on-premises need to replicate with each other.
    Requires enable_onprem_inspection = true.
  EOT
  type        = bool
  default     = false
}

# ---------------------------------------------------------------
# Azure
# ---------------------------------------------------------------
variable "azure_cidr" {
  description = "Azure private network CIDR block. Required when enable_azure_inspection = true."
  type        = string
  default     = null

  validation {
    condition     = var.azure_cidr == null || can(cidrnetmask(var.azure_cidr))
    error_message = "azure_cidr must be a valid CIDR block or null."
  }
}

variable "enable_azure_inspection" {
  description = <<-EOT
    Create and attach the Azure stateful rule group. Requires azure_cidr to
    be set. Azure traffic is scoped to AWS <-> Azure private connectivity only.
    Azure does not egress internet via this firewall and Azure <-> on-prem
    connectivity is handled independently outside of this path.
  EOT
  type        = bool
  default     = false
}

variable "enable_azure_ad_rules" {
  description = <<-EOT
    Include AD/DC port rules in the Azure stateful rule group. Enable when
    Domain Controllers in AWS and Azure need to replicate with each other.
    Requires enable_azure_inspection = true.
  EOT
  type        = bool
  default     = false
}

# ---------------------------------------------------------------
# DR
# ---------------------------------------------------------------
variable "dr_enabled" {
  description = <<-EOT
    When true, deploys a full copy of the firewall policy and rule groups
    into the DR region using the aws.dr provider alias. The DR deployment
    mirrors all settings from the primary with a -dr name suffix.
  EOT
  type        = bool
  default     = false
}
