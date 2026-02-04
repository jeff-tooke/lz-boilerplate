variable "enabled_scps" {
  description = "List of SCPs to enable. Available: deny_ec2_creation, deny_default_vpc, deny_internet_egress"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for scp in var.enabled_scps : contains([
        "deny_ec2_creation",
        "deny_default_vpc",
        "deny_internet_egress"
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
