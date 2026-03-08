################################################################################
# Customer Gateways (Primary Region)
# One per active VPN connection — represents the remote endpoint (on-prem or cloud).
################################################################################

resource "aws_customer_gateway" "this" {
  for_each = local.active_vpn_connections

  bgp_asn    = each.value.bgp_asn
  ip_address = each.value.ip_address
  type       = each.value.type

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-cgw-${each.key}"
      Region = "primary"
    }
  )
}

################################################################################
# VPN Connections (Primary Region)
# TGW-attached; one per active customer gateway.
################################################################################

resource "aws_vpn_connection" "this" {
  for_each = local.active_vpn_connections

  customer_gateway_id = aws_customer_gateway.this[each.key].id
  transit_gateway_id  = var.transit_gateway_id
  type                = each.value.type
  static_routes_only  = each.value.static_routes_only

  tunnel1_inside_cidr   = each.value.tunnel1_inside_cidr
  tunnel2_inside_cidr   = each.value.tunnel2_inside_cidr
  tunnel1_preshared_key = each.value.tunnel1_preshared_key
  tunnel2_preshared_key = each.value.tunnel2_preshared_key

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-vpn-${each.key}"
      Region = "primary"
    }
  )
}

################################################################################
# VPN Connection Static Routes (Primary Region)
# Created when destination_cidr_blocks is non-empty (static_routes_only = true).
# Key: "<conn_key>/<cidr>"
################################################################################

resource "aws_vpn_connection_route" "this" {
  for_each = local.static_routes

  vpn_connection_id      = aws_vpn_connection.this[each.value.conn_key].id
  destination_cidr_block = each.value.cidr
}

################################################################################
# VPN Remote-Connectivity Route Table (Primary Region)
# Dedicated TGW route table for all VPN attachments. A static default route
# points to the hub VPC attachment, forcing all VPN-originated traffic through
# the firewall before it reaches spoke environments.
################################################################################

resource "aws_ec2_transit_gateway_route_table" "vpn" {
  transit_gateway_id = var.transit_gateway_id

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-remote-connectivity-rt"
      Region = "primary"
    }
  )
}

# Associate each VPN attachment with the VPN route table.
resource "aws_ec2_transit_gateway_route_table_association" "vpn" {
  for_each = local.active_vpn_connections

  transit_gateway_attachment_id  = aws_vpn_connection.this[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vpn.id
}

# Static default route in vpn-rt → hub VPC attachment (firewall).
# All VPN-originated traffic is forced through the firewall.
resource "aws_ec2_transit_gateway_route" "vpn_default" {
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vpn.id
  destination_cidr_block         = local.default_route_cidr
  transit_gateway_attachment_id  = var.hub_attachment_id
}

################################################################################
# Route Propagations into Inspection Route Table (Primary Region)
# Propagate VPN attachment routes into the inspection RT so the hub VPC
# (and firewall) can return traffic to VPN endpoints.
################################################################################

resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_to_inspection" {
  for_each = local.active_vpn_connections

  transit_gateway_attachment_id  = aws_vpn_connection.this[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = var.inspection_route_table_id
}

################################################################################
# Route Propagations into Environment Route Tables (Primary Region)
# Propagate VPN attachment routes into each environment RT so spoke VPCs
# in those environments can reach remote networks via the firewall.
################################################################################

resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_to_env" {
  for_each = local.vpn_to_env_propagations

  transit_gateway_attachment_id  = aws_vpn_connection.this[each.value.conn_key].transit_gateway_attachment_id
  transit_gateway_route_table_id = var.environment_route_table_ids[each.value.env_key]
}

################################################################################
# Route Propagations into Shared Services Route Table (Primary Region)
################################################################################

resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_to_shared_services" {
  for_each = toset(local.vpn_to_shared_services)

  transit_gateway_attachment_id  = aws_vpn_connection.this[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = var.shared_services_route_table_id
}
