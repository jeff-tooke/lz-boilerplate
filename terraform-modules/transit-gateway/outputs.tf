################################################################################
# Module Version
################################################################################

output "module_version" {
  description = "Version of the transit-gateway module"
  value       = local.module_version
}

################################################################################
# Primary Region - Transit Gateway Outputs
################################################################################

output "transit_gateway_id" {
  description = "ID of the Transit Gateway"
  value       = local.transit_gateway_id
}

output "transit_gateway_arn" {
  description = "ARN of the Transit Gateway"
  value       = local.create_tgw ? aws_ec2_transit_gateway.this[0].arn : null
}

output "transit_gateway_owner_id" {
  description = "Identifier of the AWS account that owns the Transit Gateway"
  value       = local.create_tgw ? aws_ec2_transit_gateway.this[0].owner_id : null
}

output "transit_gateway_association_default_route_table_id" {
  description = "ID of the default association route table"
  value       = local.create_tgw ? aws_ec2_transit_gateway.this[0].association_default_route_table_id : null
}

output "transit_gateway_propagation_default_route_table_id" {
  description = "ID of the default propagation route table"
  value       = local.create_tgw ? aws_ec2_transit_gateway.this[0].propagation_default_route_table_id : null
}

################################################################################
# Primary Region - VPC Attachment Outputs
################################################################################

output "vpc_attachment_id" {
  description = "ID of the hub VPC Transit Gateway attachment"
  value       = aws_ec2_transit_gateway_vpc_attachment.this.id
}

################################################################################
# Primary Region - RAM Sharing Outputs
################################################################################

output "ram_resource_share_arn" {
  description = "ARN of the RAM resource share for the Transit Gateway (null if sharing not enabled)"
  value       = var.share_transit_gateway ? aws_ram_resource_share.tgw[0].arn : null
}

output "ram_principal_associations" {
  description = "List of RAM principal association ARNs"
  value       = var.share_transit_gateway ? aws_ram_principal_association.tgw[*].id : []
}

################################################################################
# DR Region - Transit Gateway Outputs
################################################################################

output "dr_transit_gateway_id" {
  description = "ID of the DR Transit Gateway (null if DR not enabled)"
  value       = var.dr_enabled ? local.dr_transit_gateway_id : null
}

output "dr_transit_gateway_arn" {
  description = "ARN of the DR Transit Gateway (null if DR not enabled or not created)"
  value       = local.dr_create_tgw ? aws_ec2_transit_gateway.dr[0].arn : null
}

output "dr_transit_gateway_owner_id" {
  description = "Identifier of the AWS account that owns the DR Transit Gateway (null if DR not enabled)"
  value       = local.dr_create_tgw ? aws_ec2_transit_gateway.dr[0].owner_id : null
}

output "dr_transit_gateway_association_default_route_table_id" {
  description = "ID of the DR default association route table (null if DR not enabled)"
  value       = local.dr_create_tgw ? aws_ec2_transit_gateway.dr[0].association_default_route_table_id : null
}

output "dr_transit_gateway_propagation_default_route_table_id" {
  description = "ID of the DR default propagation route table (null if DR not enabled)"
  value       = local.dr_create_tgw ? aws_ec2_transit_gateway.dr[0].propagation_default_route_table_id : null
}

################################################################################
# DR Region - VPC Attachment Outputs
################################################################################

output "dr_vpc_attachment_id" {
  description = "ID of the DR hub VPC Transit Gateway attachment (null if DR not enabled)"
  value       = var.dr_enabled ? aws_ec2_transit_gateway_vpc_attachment.dr[0].id : null
}

################################################################################
# DR Region - RAM Sharing Outputs
################################################################################

output "dr_ram_resource_share_arn" {
  description = "ARN of the DR RAM resource share for the Transit Gateway (null if DR not enabled or sharing not enabled)"
  value       = var.dr_enabled && var.share_transit_gateway ? aws_ram_resource_share.dr_tgw[0].arn : null
}

output "dr_ram_principal_associations" {
  description = "List of DR RAM principal association ARNs (empty if DR not enabled or sharing not enabled)"
  value       = var.dr_enabled && var.share_transit_gateway ? aws_ram_principal_association.dr_tgw[*].id : []
}
