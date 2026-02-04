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

variable "target_region" {
  description = "Which region to deploy controls to: primary or secondary"
  type        = string
  default     = "primary"

  validation {
    condition     = contains(["primary", "secondary"], var.target_region)
    error_message = "Must be 'primary' or 'secondary'."
  }
}

variable "enabled_controls" {
  description = "List of Control Tower controls to enable. Use catalog keys or full control ARNs."
  type        = list(string)
  default     = []
}

variable "target_ou_arns" {
  description = "List of OU ARNs to enable controls on"
  type        = list(string)
}

variable "custom_controls" {
  description = "Map of custom control identifiers (key => control ARN)"
  type        = map(string)
  default     = {}
}

variable "control_parameters" {
  description = "Parameters for controls that require configuration (control_key => list of key/value pairs)"
  type = map(list(object({
    key   = string
    value = string
  })))
  default = {}
}
