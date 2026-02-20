################################################################################
# Module Version
################################################################################

output "module_version" {
  description = "Version of the transit-gateway-peering module"
  value       = local.module_version
}

################################################################################
# Primary Region - Peering Outputs
################################################################################

output "peering_attachment_id" {
  description = "ID of the Transit Gateway peering attachment"
  value       = aws_ec2_transit_gateway_peering_attachment.this.id
}

output "peering_attachment_state" {
  description = "State of the Transit Gateway peering attachment"
  value       = aws_ec2_transit_gateway_peering_attachment.this.state
}

################################################################################
# DR Region - Peering Outputs
################################################################################

output "dr_peering_attachment_id" {
  description = "ID of the DR Transit Gateway peering attachment (null if DR not enabled)"
  value       = var.dr_enabled ? aws_ec2_transit_gateway_peering_attachment.dr[0].id : null
}

output "dr_peering_attachment_state" {
  description = "State of the DR Transit Gateway peering attachment (null if DR not enabled)"
  value       = var.dr_enabled ? aws_ec2_transit_gateway_peering_attachment.dr[0].state : null
}
