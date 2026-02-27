################################################################################
# Hub VPC Module
# Creates the core VPC infrastructure with 4 subnet tiers across 3 AZs
################################################################################

module "hub_vpc" {
  source = "../hub-vpc"

  name        = var.name
  environment = var.environment

  # Primary region VPC configuration
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  firewall_subnet_cidrs       = var.firewall_subnet_cidrs
  tgw_attachment_subnet_cidrs = var.tgw_attachment_subnet_cidrs
  egress_subnet_cidrs         = var.egress_subnet_cidrs
  endpoint_subnet_cidrs       = var.endpoint_subnet_cidrs

  # DNS settings
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  # DR region VPC configuration
  dr_enabled                     = var.dr_enabled
  secondary_region               = var.secondary_region
  dr_vpc_cidr                    = var.dr_vpc_cidr
  dr_availability_zones          = var.dr_availability_zones
  dr_firewall_subnet_cidrs       = var.dr_firewall_subnet_cidrs
  dr_tgw_attachment_subnet_cidrs = var.dr_tgw_attachment_subnet_cidrs
  dr_egress_subnet_cidrs         = var.dr_egress_subnet_cidrs
  dr_endpoint_subnet_cidrs       = var.dr_endpoint_subnet_cidrs

  tags = local.common_tags
}

################################################################################
# VPC Endpoints Module
# Creates gateway and interface endpoints for AWS services
################################################################################

module "vpc_endpoints" {
  source = "../vpc-endpoints"

  # Primary region endpoint configuration
  vpc_id          = module.hub_vpc.vpc_id
  subnet_ids      = module.hub_vpc.endpoint_subnet_ids_list
  route_table_ids = local.primary_gateway_endpoint_route_table_ids

  endpoints                     = var.endpoints
  security_group_ids            = var.endpoint_security_group_ids
  create_default_security_group = var.create_default_endpoint_security_group
  private_dns_enabled           = var.private_dns_enabled
  endpoint_tags                 = var.endpoint_tags
  spoke_cidr_supernet           = var.spoke_cidr_supernet
  interface_endpoint_policy     = local.effective_interface_endpoint_policy
  gateway_endpoint_policy       = local.effective_gateway_endpoint_policy

  # DR region endpoint configuration
  dr_enabled                   = var.dr_enabled
  secondary_region             = var.secondary_region
  dr_vpc_id                    = module.hub_vpc.dr_vpc_id
  dr_subnet_ids                = module.hub_vpc.dr_endpoint_subnet_ids_list
  dr_route_table_ids           = local.dr_gateway_endpoint_route_table_ids
  dr_endpoints                 = var.dr_endpoints
  dr_security_group_ids        = var.dr_endpoint_security_group_ids
  dr_spoke_cidr_supernet       = var.spoke_cidr_supernet
  dr_interface_endpoint_policy = local.effective_interface_endpoint_policy
  dr_gateway_endpoint_policy   = local.effective_gateway_endpoint_policy

  tags = local.common_tags
}

################################################################################
# Network Firewall Module
# Creates AWS Network Firewall in firewall subnets
################################################################################

module "network_firewall" {
  source = "../network-firewall"
  count  = var.enable_network_firewall ? 1 : 0

  name        = var.name
  environment = var.environment

  # Primary region
  vpc_id     = module.hub_vpc.vpc_id
  subnet_ids = module.hub_vpc.firewall_subnet_ids_list

  firewall_policy_arn = var.firewall_policy_arn

  # DR region
  dr_enabled       = var.dr_enabled
  secondary_region = var.secondary_region
  dr_vpc_id        = module.hub_vpc.dr_vpc_id
  dr_subnet_ids    = module.hub_vpc.dr_firewall_subnet_ids_list

  tags = local.common_tags
}

################################################################################
# Transit Gateway Module
# Creates or attaches to Transit Gateway
################################################################################

module "transit_gateway" {
  source = "../transit-gateway"
  count  = var.create_transit_gateway || var.transit_gateway_id != "" ? 1 : 0

  name        = var.name
  environment = var.environment

  # Primary region
  vpc_id                 = module.hub_vpc.vpc_id
  subnet_ids             = module.hub_vpc.tgw_attachment_subnet_ids_list
  transit_gateway_id     = var.transit_gateway_id
  create_transit_gateway = var.create_transit_gateway

  # DR region
  dr_enabled       = var.dr_enabled
  secondary_region = var.secondary_region
  dr_vpc_id        = module.hub_vpc.dr_vpc_id
  dr_subnet_ids    = module.hub_vpc.dr_tgw_attachment_subnet_ids_list

  tags = local.common_tags
}
