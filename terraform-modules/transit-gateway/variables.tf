################################################################################
# General Configuration
################################################################################

variable "primary_region" {
  description = "Primary AWS region for the Transit Gateway"
  type        = string
  default     = null
}

variable "secondary_region" {
  description = "Secondary AWS region for DR deployment (required if dr_enabled is true)"
  type        = string
  default     = ""
}

variable "name" {
  description = "Name prefix for Transit Gateway and associated resources"
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
# Transit Gateway Configuration
################################################################################

variable "create_transit_gateway" {
  description = "Whether to create a new Transit Gateway. Set to false when attaching to an existing TGW."
  type        = bool
  default     = true
}

variable "transit_gateway_id" {
  description = "ID of an existing Transit Gateway to attach to (required if create_transit_gateway is false)"
  type        = string
  default     = ""
}

variable "amazon_side_asn" {
  description = "Private Autonomous System Number (ASN) for the Amazon side of a BGP session"
  type        = number
  default     = 64512

  validation {
    condition     = var.amazon_side_asn >= 64512 && var.amazon_side_asn <= 65534
    error_message = "Amazon side ASN must be in the private range 64512-65534."
  }
}

variable "auto_accept_shared_attachments" {
  description = "Whether resource attachment requests are automatically accepted"
  type        = string
  default     = "enable"

  validation {
    condition     = contains(["enable", "disable"], var.auto_accept_shared_attachments)
    error_message = "auto_accept_shared_attachments must be 'enable' or 'disable'."
  }
}

variable "default_route_table_association" {
  description = "Whether resource attachments are automatically associated with the default route table"
  type        = string
  default     = "enable"

  validation {
    condition     = contains(["enable", "disable"], var.default_route_table_association)
    error_message = "default_route_table_association must be 'enable' or 'disable'."
  }
}

variable "default_route_table_propagation" {
  description = "Whether resource attachments automatically propagate routes to the default route table"
  type        = string
  default     = "enable"

  validation {
    condition     = contains(["enable", "disable"], var.default_route_table_propagation)
    error_message = "default_route_table_propagation must be 'enable' or 'disable'."
  }
}

variable "dns_support" {
  description = "Whether DNS support is enabled on the Transit Gateway"
  type        = string
  default     = "enable"

  validation {
    condition     = contains(["enable", "disable"], var.dns_support)
    error_message = "dns_support must be 'enable' or 'disable'."
  }
}

variable "vpn_ecmp_support" {
  description = "Whether VPN Equal Cost Multipath Protocol support is enabled"
  type        = string
  default     = "enable"

  validation {
    condition     = contains(["enable", "disable"], var.vpn_ecmp_support)
    error_message = "vpn_ecmp_support must be 'enable' or 'disable'."
  }
}

variable "multicast_support" {
  description = "Whether multicast is enabled on the Transit Gateway"
  type        = string
  default     = "disable"

  validation {
    condition     = contains(["enable", "disable"], var.multicast_support)
    error_message = "multicast_support must be 'enable' or 'disable'."
  }
}

################################################################################
# VPC Attachment Configuration (Primary Region)
################################################################################

variable "vpc_id" {
  description = "ID of the hub VPC to attach to the Transit Gateway"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the Transit Gateway VPC attachment (one per AZ)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "At least one subnet ID must be specified for the TGW VPC attachment."
  }
}

variable "appliance_mode_support" {
  description = "Whether Appliance Mode is enabled for the VPC attachment (enables symmetric routing for firewalls)"
  type        = string
  default     = "enable"

  validation {
    condition     = contains(["enable", "disable"], var.appliance_mode_support)
    error_message = "appliance_mode_support must be 'enable' or 'disable'."
  }
}

variable "transit_gateway_default_route_table_association" {
  description = "Whether the VPC attachment should be associated with the TGW default route table"
  type        = bool
  default     = true
}

variable "transit_gateway_default_route_table_propagation" {
  description = "Whether the VPC attachment should propagate routes to the TGW default route table"
  type        = bool
  default     = true
}

################################################################################
# RAM Sharing Configuration
################################################################################

variable "share_transit_gateway" {
  description = "Whether to share the Transit Gateway via AWS Resource Access Manager"
  type        = bool
  default     = false
}

variable "ram_principals" {
  description = "List of principals to share the Transit Gateway with. Can be OU ARNs (e.g., arn:aws:organizations::123456789012:ou/o-abc123/ou-def456), account IDs, or organization ARN."
  type        = list(string)
  default     = []
}

variable "ram_allow_external_principals" {
  description = "Whether to allow sharing with principals outside the AWS Organization"
  type        = bool
  default     = false
}

################################################################################
# DR Region Configuration
################################################################################

variable "dr_enabled" {
  description = "Feature flag to enable DR region deployment. When true, a Transit Gateway is created in the secondary region."
  type        = bool
  default     = false
}

variable "dr_vpc_id" {
  description = "ID of the DR hub VPC to attach to the DR Transit Gateway (required if dr_enabled is true)"
  type        = string
  default     = ""
}

variable "dr_subnet_ids" {
  description = "List of subnet IDs for the DR Transit Gateway VPC attachment (required if dr_enabled is true)"
  type        = list(string)
  default     = []
}

variable "dr_transit_gateway_id" {
  description = "ID of an existing DR Transit Gateway to attach to (used when create_transit_gateway is false and dr_enabled is true)"
  type        = string
  default     = ""
}

################################################################################
# Environment Route Table Configuration
################################################################################

variable "create_environment_route_tables" {
  description = "Whether to create per-environment TGW route tables for traffic segmentation and firewall enforcement. When true, the TGW default route table association and propagation are disabled."
  type        = bool
  default     = false
}

variable "environments" {
  description = "List of environment names to create dedicated TGW route tables for (e.g. [\"dev\", \"test\", \"preprod\", \"prod\"]). Only used when create_environment_route_tables is true."
  type        = list(string)
  default     = []
}

variable "create_shared_services_route_table" {
  description = "Whether to create a dedicated TGW route table for shared services attachments. Only used when create_environment_route_tables is true."
  type        = bool
  default     = false
}
