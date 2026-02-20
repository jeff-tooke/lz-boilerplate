################################################################################
# General Configuration
################################################################################

variable "name" {
  description = "Name prefix for the peering resources (e.g., prod-to-nonprod)"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., shared, network)"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Requester Configuration (Primary Region)
################################################################################

variable "transit_gateway_id" {
  description = "ID of the requester Transit Gateway"
  type        = string
}

variable "peer_transit_gateway_id" {
  description = "ID of the accepter (peer) Transit Gateway"
  type        = string
}

variable "peer_account_id" {
  description = "AWS account ID of the peer Transit Gateway owner. Defaults to the current account."
  type        = string
  default     = null
}

variable "peer_region" {
  description = "Region of the peer Transit Gateway. Defaults to the current region (same-region peering)."
  type        = string
  default     = null
}

################################################################################
# Route Configuration (Primary Region)
################################################################################

variable "requester_route_table_id" {
  description = "TGW route table ID on the requester side to add a static route towards the peer. If empty, no route is created."
  type        = string
  default     = ""
}

variable "accepter_route_table_id" {
  description = "TGW route table ID on the accepter side to add a static route towards the requester. If empty, no route is created."
  type        = string
  default     = ""
}

variable "requester_routes" {
  description = "List of CIDR blocks to route from the requester TGW towards the peer TGW (e.g., the peer environment's VPC CIDRs)"
  type        = list(string)
  default     = []
}

variable "accepter_routes" {
  description = "List of CIDR blocks to route from the accepter TGW towards the requester TGW (e.g., the requester environment's VPC CIDRs)"
  type        = list(string)
  default     = []
}

################################################################################
# DR Region Configuration
################################################################################

variable "dr_enabled" {
  description = "Feature flag to enable DR region peering. When true, a peering attachment is created between DR Transit Gateways."
  type        = bool
  default     = false
}

variable "secondary_region" {
  description = "Secondary AWS region for DR deployment (required if dr_enabled is true)"
  type        = string
  default     = ""
}

variable "dr_transit_gateway_id" {
  description = "ID of the requester DR Transit Gateway (required if dr_enabled is true)"
  type        = string
  default     = ""
}

variable "dr_peer_transit_gateway_id" {
  description = "ID of the accepter (peer) DR Transit Gateway (required if dr_enabled is true)"
  type        = string
  default     = ""
}

variable "dr_requester_route_table_id" {
  description = "DR TGW route table ID on the requester side. If empty, no route is created."
  type        = string
  default     = ""
}

variable "dr_accepter_route_table_id" {
  description = "DR TGW route table ID on the accepter side. If empty, no route is created."
  type        = string
  default     = ""
}

variable "dr_requester_routes" {
  description = "List of CIDR blocks to route from the DR requester TGW towards the DR peer TGW"
  type        = list(string)
  default     = []
}

variable "dr_accepter_routes" {
  description = "List of CIDR blocks to route from the DR accepter TGW towards the DR requester TGW"
  type        = list(string)
  default     = []
}
