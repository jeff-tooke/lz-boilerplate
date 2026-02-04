################################################################################
# Primary Region Outputs
################################################################################

output "vpc_id" {
  description = "ID of the primary hub VPC"
  value       = aws_vpc.primary.id
}

output "vpc_cidr" {
  description = "CIDR block of the primary hub VPC"
  value       = aws_vpc.primary.cidr_block
}

output "internet_gateway_id" {
  description = "ID of the primary Internet Gateway"
  value       = aws_internet_gateway.primary.id
}

# Firewall subnet outputs
output "firewall_subnet_ids" {
  description = "Map of AZ to firewall subnet ID"
  value       = { for k, v in aws_subnet.firewall : k => v.id }
}

output "firewall_subnet_cidrs" {
  description = "Map of AZ to firewall subnet CIDR"
  value       = { for k, v in aws_subnet.firewall : k => v.cidr_block }
}

output "firewall_route_table_ids" {
  description = "Map of AZ to firewall route table ID"
  value       = { for k, v in aws_route_table.firewall : k => v.id }
}

# Transit Gateway attachment subnet outputs
output "tgw_attachment_subnet_ids" {
  description = "Map of AZ to TGW attachment subnet ID"
  value       = { for k, v in aws_subnet.tgw_attachment : k => v.id }
}

output "tgw_attachment_subnet_cidrs" {
  description = "Map of AZ to TGW attachment subnet CIDR"
  value       = { for k, v in aws_subnet.tgw_attachment : k => v.cidr_block }
}

output "tgw_attachment_route_table_ids" {
  description = "Map of AZ to TGW attachment route table ID"
  value       = { for k, v in aws_route_table.tgw_attachment : k => v.id }
}

# Egress/NAT Gateway subnet outputs
output "egress_subnet_ids" {
  description = "Map of AZ to egress subnet ID"
  value       = { for k, v in aws_subnet.egress : k => v.id }
}

output "egress_subnet_cidrs" {
  description = "Map of AZ to egress subnet CIDR"
  value       = { for k, v in aws_subnet.egress : k => v.cidr_block }
}

output "egress_route_table_ids" {
  description = "Map of AZ to egress route table ID"
  value       = { for k, v in aws_route_table.egress : k => v.id }
}

output "nat_gateway_ids" {
  description = "Map of AZ to NAT Gateway ID"
  value       = { for k, v in aws_nat_gateway.primary : k => v.id }
}

output "nat_gateway_public_ips" {
  description = "Map of AZ to NAT Gateway public IP"
  value       = { for k, v in aws_nat_gateway.primary : k => v.public_ip }
}

# VPC Endpoint subnet outputs
output "endpoint_subnet_ids" {
  description = "Map of AZ to endpoint subnet ID"
  value       = { for k, v in aws_subnet.endpoints : k => v.id }
}

output "endpoint_subnet_cidrs" {
  description = "Map of AZ to endpoint subnet CIDR"
  value       = { for k, v in aws_subnet.endpoints : k => v.cidr_block }
}

output "endpoint_route_table_ids" {
  description = "Map of AZ to endpoint route table ID"
  value       = { for k, v in aws_route_table.endpoints : k => v.id }
}

# Convenience outputs for lists (useful for TGW attachments, etc.)
output "firewall_subnet_ids_list" {
  description = "List of firewall subnet IDs"
  value       = values(aws_subnet.firewall)[*].id
}

output "tgw_attachment_subnet_ids_list" {
  description = "List of TGW attachment subnet IDs"
  value       = values(aws_subnet.tgw_attachment)[*].id
}

output "egress_subnet_ids_list" {
  description = "List of egress subnet IDs"
  value       = values(aws_subnet.egress)[*].id
}

output "endpoint_subnet_ids_list" {
  description = "List of endpoint subnet IDs"
  value       = values(aws_subnet.endpoints)[*].id
}

################################################################################
# DR Region Outputs
################################################################################

output "dr_vpc_id" {
  description = "ID of the DR hub VPC (null if DR not enabled)"
  value       = var.dr_enabled ? aws_vpc.dr[0].id : null
}

output "dr_vpc_cidr" {
  description = "CIDR block of the DR hub VPC (null if DR not enabled)"
  value       = var.dr_enabled ? aws_vpc.dr[0].cidr_block : null
}

output "dr_internet_gateway_id" {
  description = "ID of the DR Internet Gateway (null if DR not enabled)"
  value       = var.dr_enabled ? aws_internet_gateway.dr[0].id : null
}

# DR Firewall subnet outputs
output "dr_firewall_subnet_ids" {
  description = "Map of AZ to DR firewall subnet ID (empty if DR not enabled)"
  value       = var.dr_enabled ? { for k, v in aws_subnet.dr_firewall : k => v.id } : {}
}

output "dr_firewall_route_table_ids" {
  description = "Map of AZ to DR firewall route table ID (empty if DR not enabled)"
  value       = var.dr_enabled ? { for k, v in aws_route_table.dr_firewall : k => v.id } : {}
}

# DR Transit Gateway attachment subnet outputs
output "dr_tgw_attachment_subnet_ids" {
  description = "Map of AZ to DR TGW attachment subnet ID (empty if DR not enabled)"
  value       = var.dr_enabled ? { for k, v in aws_subnet.dr_tgw_attachment : k => v.id } : {}
}

output "dr_tgw_attachment_route_table_ids" {
  description = "Map of AZ to DR TGW attachment route table ID (empty if DR not enabled)"
  value       = var.dr_enabled ? { for k, v in aws_route_table.dr_tgw_attachment : k => v.id } : {}
}

# DR Egress/NAT Gateway subnet outputs
output "dr_egress_subnet_ids" {
  description = "Map of AZ to DR egress subnet ID (empty if DR not enabled)"
  value       = var.dr_enabled ? { for k, v in aws_subnet.dr_egress : k => v.id } : {}
}

output "dr_egress_route_table_ids" {
  description = "Map of AZ to DR egress route table ID (empty if DR not enabled)"
  value       = var.dr_enabled ? { for k, v in aws_route_table.dr_egress : k => v.id } : {}
}

output "dr_nat_gateway_ids" {
  description = "Map of AZ to DR NAT Gateway ID (empty if DR not enabled)"
  value       = var.dr_enabled ? { for k, v in aws_nat_gateway.dr : k => v.id } : {}
}

output "dr_nat_gateway_public_ips" {
  description = "Map of AZ to DR NAT Gateway public IP (empty if DR not enabled)"
  value       = var.dr_enabled ? { for k, v in aws_nat_gateway.dr : k => v.public_ip } : {}
}

# DR VPC Endpoint subnet outputs
output "dr_endpoint_subnet_ids" {
  description = "Map of AZ to DR endpoint subnet ID (empty if DR not enabled)"
  value       = var.dr_enabled ? { for k, v in aws_subnet.dr_endpoints : k => v.id } : {}
}

output "dr_endpoint_route_table_ids" {
  description = "Map of AZ to DR endpoint route table ID (empty if DR not enabled)"
  value       = var.dr_enabled ? { for k, v in aws_route_table.dr_endpoints : k => v.id } : {}
}

# DR Convenience outputs for lists
output "dr_firewall_subnet_ids_list" {
  description = "List of DR firewall subnet IDs (empty if DR not enabled)"
  value       = var.dr_enabled ? values(aws_subnet.dr_firewall)[*].id : []
}

output "dr_tgw_attachment_subnet_ids_list" {
  description = "List of DR TGW attachment subnet IDs (empty if DR not enabled)"
  value       = var.dr_enabled ? values(aws_subnet.dr_tgw_attachment)[*].id : []
}

output "dr_egress_subnet_ids_list" {
  description = "List of DR egress subnet IDs (empty if DR not enabled)"
  value       = var.dr_enabled ? values(aws_subnet.dr_egress)[*].id : []
}

output "dr_endpoint_subnet_ids_list" {
  description = "List of DR endpoint subnet IDs (empty if DR not enabled)"
  value       = var.dr_enabled ? values(aws_subnet.dr_endpoints)[*].id : []
}
