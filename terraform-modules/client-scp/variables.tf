variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = null
}

variable "secondary_region" {
  description = "Secondary AWS region"
  type        = string
  default     = null
}

variable "allowed_regions" {
  description = "List of allowed AWS regions (overrides primary/secondary if set)"
  type        = list(string)
  default     = null
}

variable "enabled_scps" {
  description = "List of SCPs to enable. Available: deny_ec2_creation, deny_default_vpc, deny_internet_egress, deny_leave_organization, deny_unapproved_regions"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for scp in var.enabled_scps : contains([
        "deny_ec2_creation",
        "deny_default_vpc",
        "deny_internet_egress",
        "deny_leave_organization",
        "deny_unapproved_regions"
      ], scp) || can(regex("^custom_", scp))
    ])
    error_message = "Invalid SCP name. Use available SCPs or custom SCPs prefixed with 'custom_'."
  }
}

variable "target_ids" {
  description = "List of OU IDs or Account IDs to attach the SCPs to"
  type        = list(string)
  default     = []
}

variable "admin_role_arns" {
  description = "List of IAM role ARNs that are exempt from SCPs (supports wildcards)"
  type        = list(string)
  default     = []
}

variable "custom_scps" {
  description = "Map of custom SCPs to create (for extending the module)"
  type = map(object({
    name        = string
    description = string
    policy      = string
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply to SCPs"
  type        = map(string)
  default     = {}
}
