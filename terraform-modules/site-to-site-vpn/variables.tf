################################################################################
# General Configuration
################################################################################

variable "name" {
  description = "Name prefix for site-to-site VPN and associated resources"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., prod, nonprod)"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# VPN Connection Configuration
################################################################################

variable "vpn_connections" {
  description = "Map of VPN connections to create. Keys are logical names (e.g. 'it_onprem', 'it_azure'). Up to 2 connections per network domain are supported."
  type = map(object({
    enabled                 = optional(bool, true)
    bgp_asn                 = number
    ip_address              = string
    type                    = optional(string, "ipsec.1")
    static_routes_only      = optional(bool, false)
    destination_cidr_blocks = optional(list(string), [])
    tunnel1_inside_cidr     = optional(string)
    tunnel2_inside_cidr     = optional(string)
    tunnel1_preshared_key   = optional(string)
    tunnel2_preshared_key   = optional(string)
  }))
  default = {}
}

################################################################################
# Transit Gateway References (Primary Region)
################################################################################

variable "transit_gateway_id" {
  description = "ID of the Transit Gateway to attach VPN connections to"
  type        = string
}

variable "hub_attachment_id" {
  description = "ID of the hub VPC TGW attachment. Used as the next-hop for the static default route in the VPN route table, forcing VPN traffic through the firewall."
  type        = string
}

variable "inspection_route_table_id" {
  description = "ID of the inspection TGW route table. VPN attachment routes are propagated here so the hub can return traffic to VPN endpoints."
  type        = string
}

variable "environment_route_table_ids" {
  description = "Map of environment name to TGW route table ID. VPN attachment routes are propagated into each of these so spoke environments are aware of remote networks."
  type        = map(string)
  default     = {}
}

variable "shared_services_route_table_id" {
  description = "ID of the shared services TGW route table. VPN routes are propagated here when set."
  type        = string
  default     = ""
}

################################################################################
# Routing Configuration
################################################################################

variable "spoke_cidr_supernet" {
  description = "Supernet CIDR covering all spoke VPC CIDRs (e.g. 10.0.0.0/8). When set, used as the static route destination in the VPN route table instead of 0.0.0.0/0."
  type        = string
  default     = ""
}

################################################################################
# DR Region Configuration
################################################################################

variable "dr_enabled" {
  description = "Feature flag to enable DR region deployment. When true, all VPN resources are duplicated in the DR region."
  type        = bool
  default     = false
}

variable "secondary_region" {
  description = "Secondary AWS region for DR deployment (required if dr_enabled is true)"
  type        = string
  default     = ""
}

variable "dr_transit_gateway_id" {
  description = "ID of the DR Transit Gateway to attach DR VPN connections to (required if dr_enabled is true)"
  type        = string
  default     = ""
}

variable "dr_hub_attachment_id" {
  description = "ID of the DR hub VPC TGW attachment. Used as the next-hop for the static default route in the DR VPN route table."
  type        = string
  default     = ""
}

variable "dr_inspection_route_table_id" {
  description = "ID of the DR inspection TGW route table. DR VPN attachment routes are propagated here."
  type        = string
  default     = ""
}

variable "dr_environment_route_table_ids" {
  description = "Map of environment name to DR TGW route table ID. DR VPN attachment routes are propagated into each of these."
  type        = map(string)
  default     = {}
}

variable "dr_shared_services_route_table_id" {
  description = "ID of the DR shared services TGW route table. DR VPN routes are propagated here when set."
  type        = string
  default     = ""
}
