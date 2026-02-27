################################################################################
# Module Version
################################################################################

output "module_version" {
  description = "Version of the core-network-hub module"
  value       = local.module_version
}

################################################################################
# Primary Region - VPC Outputs
################################################################################

output "vpc_id" {
  description = "ID of the primary hub VPC"
  value       = module.hub_vpc.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of the primary hub VPC"
  value       = module.hub_vpc.vpc_cidr
}

output "internet_gateway_id" {
  description = "ID of the primary Internet Gateway"
  value       = module.hub_vpc.internet_gateway_id
}

################################################################################
# Primary Region - Subnet Outputs
################################################################################

output "firewall_subnet_ids" {
  description = "Map of AZ to firewall subnet ID"
  value       = module.hub_vpc.firewall_subnet_ids
}

output "firewall_subnet_ids_list" {
  description = "List of firewall subnet IDs"
  value       = module.hub_vpc.firewall_subnet_ids_list
}

output "firewall_route_table_ids" {
  description = "Map of AZ to firewall route table ID"
  value       = module.hub_vpc.firewall_route_table_ids
}

output "tgw_attachment_subnet_ids" {
  description = "Map of AZ to TGW attachment subnet ID"
  value       = module.hub_vpc.tgw_attachment_subnet_ids
}

output "tgw_attachment_subnet_ids_list" {
  description = "List of TGW attachment subnet IDs"
  value       = module.hub_vpc.tgw_attachment_subnet_ids_list
}

output "tgw_attachment_route_table_ids" {
  description = "Map of AZ to TGW attachment route table ID"
  value       = module.hub_vpc.tgw_attachment_route_table_ids
}

output "egress_subnet_ids" {
  description = "Map of AZ to egress subnet ID"
  value       = module.hub_vpc.egress_subnet_ids
}

output "egress_subnet_ids_list" {
  description = "List of egress subnet IDs"
  value       = module.hub_vpc.egress_subnet_ids_list
}

output "egress_route_table_ids" {
  description = "Map of AZ to egress route table ID"
  value       = module.hub_vpc.egress_route_table_ids
}

output "endpoint_subnet_ids" {
  description = "Map of AZ to endpoint subnet ID"
  value       = module.hub_vpc.endpoint_subnet_ids
}

output "endpoint_subnet_ids_list" {
  description = "List of endpoint subnet IDs"
  value       = module.hub_vpc.endpoint_subnet_ids_list
}

output "endpoint_route_table_ids" {
  description = "Map of AZ to endpoint route table ID"
  value       = module.hub_vpc.endpoint_route_table_ids
}

################################################################################
# Primary Region - NAT Gateway Outputs
################################################################################

output "nat_gateway_ids" {
  description = "Map of AZ to NAT Gateway ID"
  value       = module.hub_vpc.nat_gateway_ids
}

output "nat_gateway_public_ips" {
  description = "Map of AZ to NAT Gateway public IP"
  value       = module.hub_vpc.nat_gateway_public_ips
}

################################################################################
# Primary Region - VPC Endpoint Outputs
################################################################################

output "gateway_endpoints" {
  description = "Map of gateway endpoint details (S3, DynamoDB)"
  value       = module.vpc_endpoints.gateway_endpoints
}

output "interface_endpoints" {
  description = "Map of interface endpoint details"
  value       = module.vpc_endpoints.interface_endpoints
}

output "all_endpoint_ids" {
  description = "List of all VPC endpoint IDs"
  value       = module.vpc_endpoints.all_endpoint_ids
}

output "endpoint_security_group_id" {
  description = "ID of the default security group created for interface endpoints (if created)"
  value       = module.vpc_endpoints.security_group_id
}

output "endpoint_dns_entries" {
  description = "Map of endpoint service names to their DNS entries"
  value       = module.vpc_endpoints.endpoint_dns_entries
}

################################################################################
# DR Region - VPC Outputs
################################################################################

output "dr_vpc_id" {
  description = "ID of the DR hub VPC (null if DR not enabled)"
  value       = module.hub_vpc.dr_vpc_id
}

output "dr_vpc_cidr" {
  description = "CIDR block of the DR hub VPC (null if DR not enabled)"
  value       = module.hub_vpc.dr_vpc_cidr
}

output "dr_internet_gateway_id" {
  description = "ID of the DR Internet Gateway (null if DR not enabled)"
  value       = module.hub_vpc.dr_internet_gateway_id
}

################################################################################
# DR Region - Subnet Outputs
################################################################################

output "dr_firewall_subnet_ids" {
  description = "Map of AZ to DR firewall subnet ID (empty if DR not enabled)"
  value       = module.hub_vpc.dr_firewall_subnet_ids
}

output "dr_firewall_subnet_ids_list" {
  description = "List of DR firewall subnet IDs (empty if DR not enabled)"
  value       = module.hub_vpc.dr_firewall_subnet_ids_list
}

output "dr_firewall_route_table_ids" {
  description = "Map of AZ to DR firewall route table ID (empty if DR not enabled)"
  value       = module.hub_vpc.dr_firewall_route_table_ids
}

output "dr_tgw_attachment_subnet_ids" {
  description = "Map of AZ to DR TGW attachment subnet ID (empty if DR not enabled)"
  value       = module.hub_vpc.dr_tgw_attachment_subnet_ids
}

output "dr_tgw_attachment_subnet_ids_list" {
  description = "List of DR TGW attachment subnet IDs (empty if DR not enabled)"
  value       = module.hub_vpc.dr_tgw_attachment_subnet_ids_list
}

output "dr_tgw_attachment_route_table_ids" {
  description = "Map of AZ to DR TGW attachment route table ID (empty if DR not enabled)"
  value       = module.hub_vpc.dr_tgw_attachment_route_table_ids
}

output "dr_egress_subnet_ids" {
  description = "Map of AZ to DR egress subnet ID (empty if DR not enabled)"
  value       = module.hub_vpc.dr_egress_subnet_ids
}

output "dr_egress_route_table_ids" {
  description = "Map of AZ to DR egress route table ID (empty if DR not enabled)"
  value       = module.hub_vpc.dr_egress_route_table_ids
}

output "dr_egress_subnet_ids_list" {
  description = "List of DR egress subnet IDs (empty if DR not enabled)"
  value       = module.hub_vpc.dr_egress_subnet_ids_list
}

output "dr_endpoint_subnet_ids" {
  description = "Map of AZ to DR endpoint subnet ID (empty if DR not enabled)"
  value       = module.hub_vpc.dr_endpoint_subnet_ids
}

output "dr_endpoint_subnet_ids_list" {
  description = "List of DR endpoint subnet IDs (empty if DR not enabled)"
  value       = module.hub_vpc.dr_endpoint_subnet_ids_list
}

output "dr_endpoint_route_table_ids" {
  description = "Map of AZ to DR endpoint route table ID (empty if DR not enabled)"
  value       = module.hub_vpc.dr_endpoint_route_table_ids
}

################################################################################
# DR Region - NAT Gateway Outputs
################################################################################

output "dr_nat_gateway_ids" {
  description = "Map of AZ to DR NAT Gateway ID (empty if DR not enabled)"
  value       = module.hub_vpc.dr_nat_gateway_ids
}

output "dr_nat_gateway_public_ips" {
  description = "Map of AZ to DR NAT Gateway public IP (empty if DR not enabled)"
  value       = module.hub_vpc.dr_nat_gateway_public_ips
}

################################################################################
# DR Region - VPC Endpoint Outputs
################################################################################

output "dr_gateway_endpoints" {
  description = "Map of DR gateway endpoint details (empty if DR not enabled)"
  value       = module.vpc_endpoints.dr_gateway_endpoints
}

output "dr_interface_endpoints" {
  description = "Map of DR interface endpoint details (empty if DR not enabled)"
  value       = module.vpc_endpoints.dr_interface_endpoints
}

output "dr_all_endpoint_ids" {
  description = "List of all DR VPC endpoint IDs (empty if DR not enabled)"
  value       = module.vpc_endpoints.dr_all_endpoint_ids
}

output "dr_endpoint_security_group_id" {
  description = "ID of the default security group created for DR interface endpoints (null if not created)"
  value       = module.vpc_endpoints.dr_security_group_id
}

output "dr_endpoint_dns_entries" {
  description = "Map of DR endpoint service names to their DNS entries (empty if DR not enabled)"
  value       = module.vpc_endpoints.dr_endpoint_dns_entries
}

################################################################################
# Network Firewall Outputs
################################################################################

output "firewall_endpoint_ids" {
  description = "Map of AZ to Network Firewall endpoint ID"
  value       = module.network_firewall[0].firewall_endpoint_ids
}

output "dr_firewall_endpoint_ids" {
  description = "Map of AZ to DR Network Firewall endpoint ID (empty if DR not enabled)"
  value       = module.network_firewall[0].dr_firewall_endpoint_ids
}

################################################################################
# Transit Gateway Outputs
################################################################################

output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = module.transit_gateway[0].transit_gateway_id
}

output "transit_gateway_attachment_id" {
  description = "ID of the Transit Gateway VPC attachment"
  value       = module.transit_gateway[0].vpc_attachment_id
}
