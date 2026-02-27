variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name; must be one of dev, test, preprod, prod"
  type        = string

  validation {
    condition     = contains(["dev", "test", "preprod", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, preprod, prod"
  }
}

variable "vpc_cidr" {
  description = "Base CIDR block for the VPC; will be sliced into subnets automatically"
  type        = string
}

variable "number_of_azs" {
  description = "Number of Availability Zones to use (1–6); ignored when availability_zones is set"
  type        = number
  default     = 2

  validation {
    condition     = var.number_of_azs >= 1 && var.number_of_azs <= 6
    error_message = "number_of_azs must be between 1 and 6 (inclusive)"
  }
}

variable "availability_zones" {
  description = "Explicit list of AZ names to use; overrides number_of_azs when non-empty"
  type        = list(string)
  default     = []
}

variable "number_of_subnets" {
  description = "Number of subnet tiers to create per AZ (1–4)"
  type        = number
  default     = 1

  validation {
    condition     = var.number_of_subnets >= 1 && var.number_of_subnets <= 4
    error_message = "number_of_subnets must be between 1 and 4 (inclusive)"
  }
}

variable "subnet_names" {
  description = "Override tier names (e.g. [\"private\", \"data\"]); length must equal number_of_subnets when provided"
  type        = list(string)
  default     = []
}

variable "transit_gateway_id" {
  description = "Transit Gateway ID to attach to; set to empty string to skip TGW attachment"
  type        = string
  default     = ""
}

variable "environment_route_table_ids" {
  description = "Map of environment name → TGW route table ID from hub outputs; module auto-selects the entry matching var.environment"
  type        = map(string)
  default     = {}
}

variable "inspection_route_table_id" {
  description = "TGW route table ID for the inspection (firewall) VPC; spoke CIDR is propagated into this RT"
  type        = string
  default     = ""
}

variable "shared_services_route_table_id" {
  description = "TGW route table ID for shared services; spoke CIDR is propagated when this is set"
  type        = string
  default     = ""
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
  description = "Additional tags to merge onto all resources"
  type        = map(string)
  default     = {}
}
