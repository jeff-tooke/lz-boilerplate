################################################################################
# Region Configuration
# AFT customisations run in the CT home region by default (eu-west-2).
# These variables allow overrides if needed.
################################################################################

variable "primary_region" {
  description = "Primary AWS region for all resources"
  type        = string
  default     = "eu-west-2"
}

variable "secondary_region" {
  description = "DR region — used for multi-region KMS key replica (created in account customisations)"
  type        = string
  default     = "eu-west-1"
}

################################################################################
# Tagging
################################################################################

variable "tags" {
  description = "Additional tags applied to all resources in the vended account"
  type        = map(string)
  default     = {}
}
