################################################################################
# DR Region Provider
################################################################################

provider "aws" {
  alias  = "dr"
  region = var.secondary_region
}

################################################################################
# Customer Gateways (DR Region)
# Customer gateways are regional resources, but the remote endpoint IP addresses
# are region-agnostic public IPs, so the same config is reused in DR.
################################################################################

resource "aws_customer_gateway" "dr" {
  for_each = var.dr_enabled ? local.active_vpn_connections : {}
  provider = aws.dr

  bgp_asn    = each.value.bgp_asn
  ip_address = each.value.ip_address
  type       = each.value.type

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-cgw-${each.key}-dr"
      Region = "dr"
    }
  )
}

################################################################################
# VPN Connections (DR Region)
# Attached to the DR Transit Gateway.
################################################################################

resource "aws_vpn_connection" "dr" {
  for_each = var.dr_enabled ? local.active_vpn_connections : {}
  provider = aws.dr

  customer_gateway_id = aws_customer_gateway.dr[each.key].id
  transit_gateway_id  = var.dr_transit_gateway_id
  type                = each.value.type
  static_routes_only  = each.value.static_routes_only

  tunnel1_inside_cidr   = each.value.tunnel1_inside_cidr
  tunnel2_inside_cidr   = each.value.tunnel2_inside_cidr
  tunnel1_preshared_key = each.value.tunnel1_preshared_key
  tunnel2_preshared_key = each.value.tunnel2_preshared_key

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-vpn-${each.key}-dr"
      Region = "dr"
    }
  )
}

################################################################################
# VPN Connection Static Routes (DR Region)
################################################################################

resource "aws_vpn_connection_route" "dr" {
  for_each = var.dr_enabled ? local.static_routes : {}
  provider = aws.dr

  vpn_connection_id      = aws_vpn_connection.dr[each.value.conn_key].id
  destination_cidr_block = each.value.cidr
}

################################################################################
# VPN Remote-Connectivity Route Table (DR Region)
################################################################################

resource "aws_ec2_transit_gateway_route_table" "vpn_dr" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr

  transit_gateway_id = var.dr_transit_gateway_id

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-remote-connectivity-rt-dr"
      Region = "dr"
    }
  )
}

# Associate each DR VPN attachment with the DR VPN route table.
resource "aws_ec2_transit_gateway_route_table_association" "vpn_dr" {
  for_each = var.dr_enabled ? local.active_vpn_connections : {}
  provider = aws.dr

  transit_gateway_attachment_id  = aws_vpn_connection.dr[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vpn_dr[0].id
}

# Static default route in DR vpn-rt → DR hub VPC attachment (firewall).
resource "aws_ec2_transit_gateway_route" "vpn_default_dr" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.vpn_dr[0].id
  destination_cidr_block         = local.default_route_cidr
  transit_gateway_attachment_id  = var.dr_hub_attachment_id
}

################################################################################
# Route Propagations into DR Inspection Route Table
################################################################################

resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_to_inspection_dr" {
  for_each = var.dr_enabled ? local.active_vpn_connections : {}
  provider = aws.dr

  transit_gateway_attachment_id  = aws_vpn_connection.dr[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = var.dr_inspection_route_table_id
}

################################################################################
# Route Propagations into DR Environment Route Tables
################################################################################

resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_to_env_dr" {
  for_each = var.dr_enabled ? local.dr_vpn_to_env_propagations : {}
  provider = aws.dr

  transit_gateway_attachment_id  = aws_vpn_connection.dr[each.value.conn_key].transit_gateway_attachment_id
  transit_gateway_route_table_id = var.dr_environment_route_table_ids[each.value.env_key]
}

################################################################################
# Route Propagations into DR Shared Services Route Table
################################################################################

resource "aws_ec2_transit_gateway_route_table_propagation" "vpn_to_shared_services_dr" {
  for_each = var.dr_enabled ? toset(local.dr_vpn_to_shared_services) : toset([])
  provider = aws.dr

  transit_gateway_attachment_id  = aws_vpn_connection.dr[each.key].transit_gateway_attachment_id
  transit_gateway_route_table_id = var.dr_shared_services_route_table_id
}
