variable "common_tags" {
  description = "Tags applied to all resources across both domains"
  type        = map(string)
  default     = {}
}

variable "primary_region" {
  description = "AWS region for primary deployment"
  type        = string
}

variable "dr_region" {
  description = "AWS region for DR deployment"
  type        = string
}

variable "dr_enabled" {
  description = "When true, deploys firewall policy and rule groups to the DR region"
  type        = bool
  default     = false
}

variable "it_internal_cidr" {
  description = "Internal CIDR for the IT domain primary network"
  type        = string
}

variable "it_dr_internal_cidr" {
  description = "Internal CIDR for the IT domain DR network. Required when dr_enabled = true."
  type        = string
  default     = null
}

variable "it_onprem_cidr" {
  description = "On-premises CIDR for IT domain. Required when it_enable_onprem_inspection = true."
  type        = string
  default     = null
}

variable "it_azure_cidr" {
  description = "Azure private network CIDR for IT domain. Required when it_enable_azure_inspection = true."
  type        = string
  default     = null
}

variable "it_allowed_egress_domains" {
  description = "Domains permitted for IT internet egress"
  type        = list(string)
  default     = []
}

variable "it_enable_ad_rules" {
  description = "Enable AD port rules for IT east-west traffic"
  type        = bool
  default     = false
}

variable "it_enable_onprem_inspection" {
  description = "Enable on-premises inspection for IT domain"
  type        = bool
  default     = false
}

variable "it_enable_onprem_ad_rules" {
  description = "Enable AD port rules for IT on-prem stateful rule group"
  type        = bool
  default     = false
}

variable "it_enable_azure_inspection" {
  description = "Enable Azure inspection for IT domain"
  type        = bool
  default     = false
}

variable "it_enable_azure_ad_rules" {
  description = "Enable AD port rules for IT Azure stateful rule group"
  type        = bool
  default     = false
}

variable "ot_internal_cidr" {
  description = "Internal CIDR for the OT domain primary network"
  type        = string
}

variable "ot_dr_internal_cidr" {
  description = "Internal CIDR for the OT domain DR network. Required when dr_enabled = true."
  type        = string
  default     = null
}

variable "ot_onprem_cidr" {
  description = "On-premises CIDR for OT domain. Required when ot_enable_onprem_inspection = true."
  type        = string
  default     = null
}

variable "ot_azure_cidr" {
  description = "Azure private network CIDR for OT domain. Required when ot_enable_azure_inspection = true."
  type        = string
  default     = null
}

variable "ot_enable_ad_rules" {
  description = "Enable AD port rules for OT east-west traffic"
  type        = bool
  default     = false
}

variable "ot_enable_onprem_inspection" {
  description = "Enable on-premises inspection for OT domain"
  type        = bool
  default     = false
}

variable "ot_enable_onprem_ad_rules" {
  description = "Enable AD port rules for OT on-prem stateful rule group"
  type        = bool
  default     = false
}

variable "ot_enable_azure_inspection" {
  description = "Enable Azure inspection for OT domain"
  type        = bool
  default     = false
}

variable "ot_enable_azure_ad_rules" {
  description = "Enable AD port rules for OT Azure stateful rule group"
  type        = bool
  default     = false
}

