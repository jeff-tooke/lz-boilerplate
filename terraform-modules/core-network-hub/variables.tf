################################################################################
# General Configuration
################################################################################

variable "name" {
  description = "Name prefix for the hub network and associated resources"
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
# Primary Region Configuration
################################################################################

variable "primary_region" {
  description = "Primary AWS region for the hub network"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the primary VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones to use (must be 3 for HA)"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) == 3
    error_message = "Exactly 3 availability zones must be specified for HA."
  }
}

variable "firewall_subnet_cidrs" {
  description = "List of CIDR blocks for firewall subnets (/28), one per AZ"
  type        = list(string)

  validation {
    condition     = length(var.firewall_subnet_cidrs) == 3
    error_message = "Exactly 3 firewall subnet CIDRs must be specified."
  }
}

variable "tgw_attachment_subnet_cidrs" {
  description = "List of CIDR blocks for Transit Gateway attachment subnets (/28), one per AZ"
  type        = list(string)

  validation {
    condition     = length(var.tgw_attachment_subnet_cidrs) == 3
    error_message = "Exactly 3 TGW attachment subnet CIDRs must be specified."
  }
}

variable "egress_subnet_cidrs" {
  description = "List of CIDR blocks for egress/NAT Gateway subnets (/28), one per AZ"
  type        = list(string)

  validation {
    condition     = length(var.egress_subnet_cidrs) == 3
    error_message = "Exactly 3 egress subnet CIDRs must be specified."
  }
}

variable "endpoint_subnet_cidrs" {
  description = "List of CIDR blocks for VPC endpoint subnets (/25), one per AZ"
  type        = list(string)

  validation {
    condition     = length(var.endpoint_subnet_cidrs) == 3
    error_message = "Exactly 3 endpoint subnet CIDRs must be specified."
  }
}

################################################################################
# VPC Endpoints Configuration
################################################################################

variable "endpoints" {
  description = "List of full AWS VPC endpoint service names for primary region (e.g., 'com.amazonaws.eu-west-1.s3')"
  type        = list(string)
  default     = []
}

variable "endpoint_security_group_ids" {
  description = "List of security group IDs to attach to interface endpoints. If empty, a default security group will be created."
  type        = list(string)
  default     = []
}

variable "create_default_endpoint_security_group" {
  description = "Whether to create a default security group for interface endpoints when security_group_ids is empty"
  type        = bool
  default     = true
}

variable "private_dns_enabled" {
  description = "Whether to enable private DNS for interface endpoints"
  type        = bool
  default     = true
}

variable "endpoint_tags" {
  description = "Additional tags to apply to specific endpoints. Map of service name to tags."
  type        = map(map(string))
  default     = {}
}

################################################################################
# DNS Configuration
################################################################################

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

################################################################################
# DR Region Configuration
################################################################################

variable "dr_enabled" {
  description = "Feature flag to enable DR region deployment. When true, all resources are duplicated in the DR region."
  type        = bool
  default     = false
}

variable "secondary_region" {
  description = "Secondary AWS region for DR deployment (required if dr_enabled is true)"
  type        = string
  default     = ""
}

variable "dr_vpc_cidr" {
  description = "CIDR block for the DR VPC (required if dr_enabled is true, must not overlap with primary)"
  type        = string
  default     = ""
}

variable "dr_availability_zones" {
  description = "List of availability zones for DR region (required if dr_enabled is true, must be 3 for HA)"
  type        = list(string)
  default     = []
}

variable "dr_firewall_subnet_cidrs" {
  description = "List of CIDR blocks for DR firewall subnets (/28)"
  type        = list(string)
  default     = []
}

variable "dr_tgw_attachment_subnet_cidrs" {
  description = "List of CIDR blocks for DR Transit Gateway attachment subnets (/28)"
  type        = list(string)
  default     = []
}

variable "dr_egress_subnet_cidrs" {
  description = "List of CIDR blocks for DR egress/NAT Gateway subnets (/28)"
  type        = list(string)
  default     = []
}

variable "dr_endpoint_subnet_cidrs" {
  description = "List of CIDR blocks for DR VPC endpoint subnets (/25)"
  type        = list(string)
  default     = []
}

variable "dr_endpoints" {
  description = "List of full AWS VPC endpoint service names for DR region (e.g., 'com.amazonaws.eu-west-2.s3'). Must use DR region in service names."
  type        = list(string)
  default     = []
}

variable "dr_endpoint_security_group_ids" {
  description = "List of security group IDs to attach to DR interface endpoints. If empty, a default security group will be created."
  type        = list(string)
  default     = []
}

################################################################################
# Future: Network Firewall Configuration (placeholder)
################################################################################

# variable "enable_network_firewall" {
#   description = "Enable AWS Network Firewall deployment"
#   type        = bool
#   default     = false
# }

# variable "firewall_policy_arn" {
#   description = "ARN of the firewall policy to attach"
#   type        = string
#   default     = ""
# }

################################################################################
# Future: Transit Gateway Configuration (placeholder)
################################################################################

# variable "transit_gateway_id" {
#   description = "ID of an existing Transit Gateway to attach to"
#   type        = string
#   default     = ""
# }

# variable "create_transit_gateway" {
#   description = "Create a new Transit Gateway"
#   type        = bool
#   default     = false
# }
