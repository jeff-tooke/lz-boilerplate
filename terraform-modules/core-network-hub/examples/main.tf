################################################################################
# Example: Core Network Hub with DR Enabled
# This example demonstrates deploying a complete hub network with multi-region DR
################################################################################

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

################################################################################
# Variables
################################################################################

variable "dr_enabled" {
  description = "Enable DR region deployment"
  type        = bool
  default     = false
}

locals {
  # Primary region configuration
  primary_region = "eu-west-1"
  primary_azs    = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  # DR region configuration
  dr_region = "eu-west-2"
  dr_azs    = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]

  # Common endpoint services
  primary_endpoints = [
    "com.amazonaws.eu-west-1.s3",
    "com.amazonaws.eu-west-1.dynamodb",
    "com.amazonaws.eu-west-1.ssm",
    "com.amazonaws.eu-west-1.ssmmessages",
    "com.amazonaws.eu-west-1.ec2messages",
    "com.amazonaws.eu-west-1.sts",
    "com.amazonaws.eu-west-1.kms",
    "com.amazonaws.eu-west-1.secretsmanager",
    "com.amazonaws.eu-west-1.logs"
  ]

  dr_endpoints = [
    "com.amazonaws.eu-west-2.s3",
    "com.amazonaws.eu-west-2.dynamodb",
    "com.amazonaws.eu-west-2.ssm",
    "com.amazonaws.eu-west-2.ssmmessages",
    "com.amazonaws.eu-west-2.ec2messages",
    "com.amazonaws.eu-west-2.sts",
    "com.amazonaws.eu-west-2.kms",
    "com.amazonaws.eu-west-2.secretsmanager",
    "com.amazonaws.eu-west-2.logs"
  ]

  common_tags = {
    Project   = "core-network"
    Terraform = "true"
    Owner     = "platform-team"
  }
}

################################################################################
# Production Hub Network
################################################################################

module "production_hub" {
  source = "../"

  name           = "prod-hub"
  environment    = "production"
  primary_region = local.primary_region

  # Primary region VPC configuration
  vpc_cidr           = "10.0.0.0/20"
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

  # VPC Endpoints
  endpoints = local.primary_endpoints

  # DR Configuration
  dr_enabled            = var.dr_enabled
  dr_region             = local.dr_region
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

  dr_endpoints = local.dr_endpoints

  tags = merge(local.common_tags, {
    Domain = "production"
  })
}

################################################################################
# Non-Production Hub Network
################################################################################

module "nonproduction_hub" {
  source = "../"

  name           = "nonprod-hub"
  environment    = "nonproduction"
  primary_region = local.primary_region

  # Primary region VPC configuration
  vpc_cidr           = "10.2.0.0/20"
  availability_zones = local.primary_azs

  firewall_subnet_cidrs = [
    "10.2.0.0/28",
    "10.2.0.16/28",
    "10.2.0.32/28"
  ]

  tgw_attachment_subnet_cidrs = [
    "10.2.0.48/28",
    "10.2.0.64/28",
    "10.2.0.80/28"
  ]

  egress_subnet_cidrs = [
    "10.2.0.96/28",
    "10.2.0.112/28",
    "10.2.0.128/28"
  ]

  endpoint_subnet_cidrs = [
    "10.2.1.0/25",
    "10.2.1.128/25",
    "10.2.2.0/25"
  ]

  # VPC Endpoints
  endpoints = local.primary_endpoints

  # DR Configuration
  dr_enabled            = var.dr_enabled
  dr_region             = local.dr_region
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

  dr_endpoints = local.dr_endpoints

  tags = merge(local.common_tags, {
    Domain = "nonproduction"
  })
}

################################################################################
# Outputs
################################################################################

output "production_hub" {
  description = "Production hub network details"
  value = {
    module_version = module.production_hub.module_version
    vpc_id         = module.production_hub.vpc_id
    vpc_cidr       = module.production_hub.vpc_cidr

    subnets = {
      firewall       = module.production_hub.firewall_subnet_ids
      tgw_attachment = module.production_hub.tgw_attachment_subnet_ids
      egress         = module.production_hub.egress_subnet_ids
      endpoints      = module.production_hub.endpoint_subnet_ids
    }

    nat_gateways = module.production_hub.nat_gateway_ids
    endpoints    = module.production_hub.all_endpoint_ids
  }
}

output "production_hub_dr" {
  description = "Production hub DR network details (populated when dr_enabled=true)"
  value = {
    vpc_id   = module.production_hub.dr_vpc_id
    vpc_cidr = module.production_hub.dr_vpc_cidr

    subnets = {
      firewall       = module.production_hub.dr_firewall_subnet_ids
      tgw_attachment = module.production_hub.dr_tgw_attachment_subnet_ids
      egress         = module.production_hub.dr_egress_subnet_ids
      endpoints      = module.production_hub.dr_endpoint_subnet_ids
    }

    nat_gateways = module.production_hub.dr_nat_gateway_ids
    endpoints    = module.production_hub.dr_all_endpoint_ids
  }
}

output "nonproduction_hub" {
  description = "Non-production hub network details"
  value = {
    module_version = module.nonproduction_hub.module_version
    vpc_id         = module.nonproduction_hub.vpc_id
    vpc_cidr       = module.nonproduction_hub.vpc_cidr

    subnets = {
      firewall       = module.nonproduction_hub.firewall_subnet_ids
      tgw_attachment = module.nonproduction_hub.tgw_attachment_subnet_ids
      egress         = module.nonproduction_hub.egress_subnet_ids
      endpoints      = module.nonproduction_hub.endpoint_subnet_ids
    }

    nat_gateways = module.nonproduction_hub.nat_gateway_ids
    endpoints    = module.nonproduction_hub.all_endpoint_ids
  }
}

output "nonproduction_hub_dr" {
  description = "Non-production hub DR network details (populated when dr_enabled=true)"
  value = {
    vpc_id   = module.nonproduction_hub.dr_vpc_id
    vpc_cidr = module.nonproduction_hub.dr_vpc_cidr

    subnets = {
      firewall       = module.nonproduction_hub.dr_firewall_subnet_ids
      tgw_attachment = module.nonproduction_hub.dr_tgw_attachment_subnet_ids
      egress         = module.nonproduction_hub.dr_egress_subnet_ids
      endpoints      = module.nonproduction_hub.dr_endpoint_subnet_ids
    }

    nat_gateways = module.nonproduction_hub.dr_nat_gateway_ids
    endpoints    = module.nonproduction_hub.dr_all_endpoint_ids
  }
}
