################################################################################
# Example: Two Hub VPCs for Different System-Domain Workloads
# This example demonstrates calling the core-network module multiple times
################################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

# Variables for DR toggle
variable "dr_enabled" {
  description = "Enable DR region deployment"
  type        = bool
  default     = false
}

locals {
  primary_azs = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  dr_azs      = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]

  common_tags = {
    Project   = "core-network"
    Terraform = "true"
  }
}

################################################################################
# Hub VPC 1: Production Workloads
################################################################################

module "hub_vpc_production" {
  source = "../"

  name        = "prod-hub"
  environment = "production"
  vpc_cidr    = "10.0.0.0/20"

  availability_zones = local.primary_azs

  # /28 subnets = 16 IPs each (11 usable after AWS reserved)
  firewall_subnet_cidrs = [
    "10.0.0.0/28",  # AZ-a
    "10.0.0.16/28", # AZ-b
    "10.0.0.32/28"  # AZ-c
  ]

  tgw_attachment_subnet_cidrs = [
    "10.0.0.48/28", # AZ-a
    "10.0.0.64/28", # AZ-b
    "10.0.0.80/28"  # AZ-c
  ]

  egress_subnet_cidrs = [
    "10.0.0.96/28",  # AZ-a
    "10.0.0.112/28", # AZ-b
    "10.0.0.128/28"  # AZ-c
  ]

  # /25 subnets = 128 IPs each (123 usable after AWS reserved)
  endpoint_subnet_cidrs = [
    "10.0.1.0/25",   # AZ-a
    "10.0.1.128/25", # AZ-b
    "10.0.2.0/25"    # AZ-c
  ]

  # DR Configuration
  dr_enabled            = var.dr_enabled
  dr_region             = "eu-west-2"
  dr_vpc_cidr           = "10.1.0.0/20"
  dr_availability_zones = local.dr_azs

  dr_firewall_subnet_cidrs = [
    "10.1.0.0/28",
    "10.1.0.16/28",
    "10.1.0.32/28"
  ]

  dr_tgw_attachment_subnet_cidrs = [
    "10.1.0.48/28",
    "10.1.0.64/28",
    "10.1.0.80/28"
  ]

  dr_egress_subnet_cidrs = [
    "10.1.0.96/28",
    "10.1.0.112/28",
    "10.1.0.128/28"
  ]

  dr_endpoint_subnet_cidrs = [
    "10.1.1.0/25",
    "10.1.1.128/25",
    "10.1.2.0/25"
  ]

  tags = merge(local.common_tags, {
    Domain = "production"
  })
}

################################################################################
# Hub VPC 2: Non-Production Workloads
################################################################################

module "hub_vpc_nonproduction" {
  source = "../"

  name        = "nonprod-hub"
  environment = "nonproduction"
  vpc_cidr    = "10.2.0.0/20"

  availability_zones = local.primary_azs

  # /28 subnets = 16 IPs each (11 usable after AWS reserved)
  firewall_subnet_cidrs = [
    "10.2.0.0/28",  # AZ-a
    "10.2.0.16/28", # AZ-b
    "10.2.0.32/28"  # AZ-c
  ]

  tgw_attachment_subnet_cidrs = [
    "10.2.0.48/28", # AZ-a
    "10.2.0.64/28", # AZ-b
    "10.2.0.80/28"  # AZ-c
  ]

  egress_subnet_cidrs = [
    "10.2.0.96/28",  # AZ-a
    "10.2.0.112/28", # AZ-b
    "10.2.0.128/28"  # AZ-c
  ]

  # /25 subnets = 128 IPs each (123 usable after AWS reserved)
  endpoint_subnet_cidrs = [
    "10.2.1.0/25",   # AZ-a
    "10.2.1.128/25", # AZ-b
    "10.2.2.0/25"    # AZ-c
  ]

  # DR Configuration
  dr_enabled            = var.dr_enabled
  dr_region             = "eu-west-2"
  dr_vpc_cidr           = "10.3.0.0/20"
  dr_availability_zones = local.dr_azs

  dr_firewall_subnet_cidrs = [
    "10.3.0.0/28",
    "10.3.0.16/28",
    "10.3.0.32/28"
  ]

  dr_tgw_attachment_subnet_cidrs = [
    "10.3.0.48/28",
    "10.3.0.64/28",
    "10.3.0.80/28"
  ]

  dr_egress_subnet_cidrs = [
    "10.3.0.96/28",
    "10.3.0.112/28",
    "10.3.0.128/28"
  ]

  dr_endpoint_subnet_cidrs = [
    "10.3.1.0/25",
    "10.3.1.128/25",
    "10.3.2.0/25"
  ]

  tags = merge(local.common_tags, {
    Domain = "nonproduction"
  })
}

################################################################################
# Outputs
################################################################################

output "production_hub" {
  description = "Production hub VPC details"
  value = {
    vpc_id                    = module.hub_vpc_production.vpc_id
    vpc_cidr                  = module.hub_vpc_production.vpc_cidr
    firewall_subnet_ids       = module.hub_vpc_production.firewall_subnet_ids
    tgw_attachment_subnet_ids = module.hub_vpc_production.tgw_attachment_subnet_ids
    egress_subnet_ids         = module.hub_vpc_production.egress_subnet_ids
    endpoint_subnet_ids       = module.hub_vpc_production.endpoint_subnet_ids
    nat_gateway_ids           = module.hub_vpc_production.nat_gateway_ids
  }
}

output "nonproduction_hub" {
  description = "Non-production hub VPC details"
  value = {
    vpc_id                    = module.hub_vpc_nonproduction.vpc_id
    vpc_cidr                  = module.hub_vpc_nonproduction.vpc_cidr
    firewall_subnet_ids       = module.hub_vpc_nonproduction.firewall_subnet_ids
    tgw_attachment_subnet_ids = module.hub_vpc_nonproduction.tgw_attachment_subnet_ids
    egress_subnet_ids         = module.hub_vpc_nonproduction.egress_subnet_ids
    endpoint_subnet_ids       = module.hub_vpc_nonproduction.endpoint_subnet_ids
    nat_gateway_ids           = module.hub_vpc_nonproduction.nat_gateway_ids
  }
}

# DR outputs (only populated when dr_enabled = true)
output "production_hub_dr" {
  description = "Production hub VPC DR details"
  value = {
    vpc_id                    = module.hub_vpc_production.dr_vpc_id
    vpc_cidr                  = module.hub_vpc_production.dr_vpc_cidr
    firewall_subnet_ids       = module.hub_vpc_production.dr_firewall_subnet_ids
    tgw_attachment_subnet_ids = module.hub_vpc_production.dr_tgw_attachment_subnet_ids
    egress_subnet_ids         = module.hub_vpc_production.dr_egress_subnet_ids
    endpoint_subnet_ids       = module.hub_vpc_production.dr_endpoint_subnet_ids
    nat_gateway_ids           = module.hub_vpc_production.dr_nat_gateway_ids
  }
}

output "nonproduction_hub_dr" {
  description = "Non-production hub VPC DR details"
  value = {
    vpc_id                    = module.hub_vpc_nonproduction.dr_vpc_id
    vpc_cidr                  = module.hub_vpc_nonproduction.dr_vpc_cidr
    firewall_subnet_ids       = module.hub_vpc_nonproduction.dr_firewall_subnet_ids
    tgw_attachment_subnet_ids = module.hub_vpc_nonproduction.dr_tgw_attachment_subnet_ids
    egress_subnet_ids         = module.hub_vpc_nonproduction.dr_egress_subnet_ids
    endpoint_subnet_ids       = module.hub_vpc_nonproduction.dr_endpoint_subnet_ids
    nat_gateway_ids           = module.hub_vpc_nonproduction.dr_nat_gateway_ids
  }
}
