################################################################################
# General Configuration
################################################################################

variable "name" {
  description = "Name prefix for resources created by this module"
  type        = string
}

variable "environment" {
  description = "Environment name for the spoke being attached (e.g., dev, test, preprod, prod)"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Spoke Attachment Configuration
################################################################################

variable "attachment_id" {
  description = "ID of the spoke VPC Transit Gateway attachment to wire into route tables"
  type        = string
}

variable "environment_route_table_id" {
  description = "ID of the environment-specific TGW route table to associate this spoke attachment with"
  type        = string
}

variable "inspection_route_table_id" {
  description = "ID of the inspection (hub/firewall) TGW route table. The spoke CIDR is propagated here so the firewall can return traffic to the spoke."
  type        = string
}

variable "shared_services_route_table_id" {
  description = "ID of the shared services TGW route table. When provided, the spoke CIDR is propagated here so shared services can respond to requests from this spoke."
  type        = string
  default     = ""
}
