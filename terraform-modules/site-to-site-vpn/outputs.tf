################################################################################
# Module Version
################################################################################

output "module_version" {
  description = "Version of the site-to-site-vpn module"
  value       = local.module_version
}

################################################################################
# Primary Region - Customer Gateway Outputs
################################################################################

output "customer_gateway_ids" {
  description = "Map of VPN connection name to primary customer gateway ID"
  value       = { for k, v in aws_customer_gateway.this : k => v.id }
}

################################################################################
# Primary Region - VPN Connection Outputs
################################################################################

output "vpn_connection_ids" {
  description = "Map of VPN connection name to primary VPN connection ID"
  value       = { for k, v in aws_vpn_connection.this : k => v.id }
}

output "vpn_tunnel1_addresses" {
  description = "Map of VPN connection name to primary tunnel 1 outside IP address"
  value       = { for k, v in aws_vpn_connection.this : k => v.tunnel1_address }
}

output "vpn_tunnel2_addresses" {
  description = "Map of VPN connection name to primary tunnel 2 outside IP address"
  value       = { for k, v in aws_vpn_connection.this : k => v.tunnel2_address }
}

output "vpn_transit_gateway_attachment_ids" {
  description = "Map of VPN connection name to primary TGW attachment ID"
  value       = { for k, v in aws_vpn_connection.this : k => v.transit_gateway_attachment_id }
}

################################################################################
# Primary Region - Route Table Outputs
################################################################################

output "vpn_route_table_id" {
  description = "ID of the primary remote-connectivity TGW route table for VPN attachments"
  value       = aws_ec2_transit_gateway_route_table.vpn.id
}

################################################################################
# DR Region - Customer Gateway Outputs
################################################################################

output "dr_customer_gateway_ids" {
  description = "Map of VPN connection name to DR customer gateway ID (empty map if DR not enabled)"
  value       = var.dr_enabled ? { for k, v in aws_customer_gateway.dr : k => v.id } : {}
}

################################################################################
# DR Region - VPN Connection Outputs
################################################################################

output "dr_vpn_connection_ids" {
  description = "Map of VPN connection name to DR VPN connection ID (empty map if DR not enabled)"
  value       = var.dr_enabled ? { for k, v in aws_vpn_connection.dr : k => v.id } : {}
}

output "dr_vpn_tunnel1_addresses" {
  description = "Map of VPN connection name to DR tunnel 1 outside IP address (empty map if DR not enabled)"
  value       = var.dr_enabled ? { for k, v in aws_vpn_connection.dr : k => v.tunnel1_address } : {}
}

output "dr_vpn_tunnel2_addresses" {
  description = "Map of VPN connection name to DR tunnel 2 outside IP address (empty map if DR not enabled)"
  value       = var.dr_enabled ? { for k, v in aws_vpn_connection.dr : k => v.tunnel2_address } : {}
}

output "dr_vpn_transit_gateway_attachment_ids" {
  description = "Map of VPN connection name to DR TGW attachment ID (empty map if DR not enabled)"
  value       = var.dr_enabled ? { for k, v in aws_vpn_connection.dr : k => v.transit_gateway_attachment_id } : {}
}

################################################################################
# DR Region - Route Table Outputs
################################################################################

output "dr_vpn_route_table_id" {
  description = "ID of the DR remote-connectivity TGW route table for VPN attachments (null if DR not enabled)"
  value       = var.dr_enabled ? aws_ec2_transit_gateway_route_table.vpn_dr[0].id : null
}
