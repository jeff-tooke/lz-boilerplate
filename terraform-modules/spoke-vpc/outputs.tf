output "module_version" {
  description = "Version of this module"
  value       = local.module_version
}

output "vpc_id" {
  description = "ID of the spoke VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the spoke VPC"
  value       = aws_vpc.this.cidr_block
}

output "subnet_ids" {
  description = "Map of tier name → list of subnet IDs in that tier (one per AZ)"
  value = {
    for tier_name in local.effective_subnet_names :
    tier_name => [
      for az in local.selected_azs :
      aws_subnet.this["${tier_name}-${az}"].id
    ]
  }
}

output "subnet_ids_by_az" {
  description = "Map of AZ → list of subnet IDs in that AZ (one per tier)"
  value = {
    for az in local.selected_azs :
    az => [
      for tier_name in local.effective_subnet_names :
      aws_subnet.this["${tier_name}-${az}"].id
    ]
  }
}

output "subnet_ids_flat" {
  description = "Flat list of all subnet IDs"
  value       = [for s in aws_subnet.this : s.id]
}

output "subnet_cidrs" {
  description = "Map of \"tier-az\" key → computed CIDR block"
  value       = { for k, v in local.subnet_map : k => v.cidr }
}

output "route_table_ids" {
  description = "Map of tier name → list of route table IDs in that tier (one per AZ)"
  value = {
    for tier_name in local.effective_subnet_names :
    tier_name => [
      for az in local.selected_azs :
      aws_route_table.this["${tier_name}-${az}"].id
    ]
  }
}

output "tgw_attachment_id" {
  description = "TGW VPC attachment ID; null when transit_gateway_id is not set"
  value       = local.create_tgw_attachment ? aws_ec2_transit_gateway_vpc_attachment.this[0].id : null
}

output "tgw_attachment_subnet_ids" {
  description = "Subnet IDs used for the TGW attachment (first tier, one per AZ)"
  value       = local.create_tgw_attachment ? local.tgw_attachment_subnet_ids : []
}

output "resolved_environment_route_table_id" {
  description = "The TGW route table ID auto-selected from environment_route_table_ids for var.environment; null when not provided"
  value       = local.environment_route_table_id != "" ? local.environment_route_table_id : null
}
