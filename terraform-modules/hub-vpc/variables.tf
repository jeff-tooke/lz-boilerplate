variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = null
}

variable "secondary_region" {
  description = "Secondary AWS region for DR deployment (required if dr_enabled is true)"
  type        = string
  default     = ""
}

variable "name" {
  description = "Name prefix for the hub VPC and associated resources"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., prod, nonprod)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
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

variable "dr_enabled" {
  description = "Feature flag to enable DR region deployment"
  type        = bool
  default     = false
}


variable "dr_vpc_cidr" {
  description = "CIDR block for the DR VPC (required if dr_enabled is true)"
  type        = string
  default     = ""
}

variable "dr_availability_zones" {
  description = "List of availability zones for DR region (required if dr_enabled is true)"
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

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
