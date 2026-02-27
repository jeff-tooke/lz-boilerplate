################################################################################
# Firewall Inspection Routing
# Routes all spoke traffic through per-AZ Network Firewall endpoints
################################################################################

# ── 1. TGW attachment subnets → Firewall (default) ───────────────────────────
# Catches all spoke traffic not matched by a more-specific route below.
# Covers internet egress and east-west traffic.
resource "aws_route" "tgw_to_firewall" {
  for_each = module.hub_vpc.tgw_attachment_route_table_ids

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = local.firewall_endpoint_ids[each.key]
}

# ── 2. TGW attachment subnets → Firewall (endpoint subnets) ──────────────────
# The VPC local route (hub /16) beats 0.0.0.0/0 for traffic destined to
# endpoint ENI IPs, which would bypass the firewall. These more-specific
# per-subnet routes (/25) override the local route and force spoke→endpoint
# traffic through the firewall, enabling symmetric stateful inspection.
resource "aws_route" "tgw_to_endpoint_via_firewall" {
  for_each = local.tgw_to_endpoint_routes

  route_table_id         = each.value.rt_id
  destination_cidr_block = each.value.endpoint_cidr
  vpc_endpoint_id        = local.firewall_endpoint_ids[each.value.az]
}

# ── 3. Firewall subnets → NAT Gateway (internet egress post-inspection) ───────
resource "aws_route" "firewall_to_nat" {
  for_each = module.hub_vpc.firewall_route_table_ids

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = module.hub_vpc.nat_gateway_ids[each.key]
}

# ── 4. Firewall subnets → TGW (east-west + endpoint return post-inspection) ───
# More specific than 0.0.0.0/0 above, wins for all spoke-destined traffic.
resource "aws_route" "firewall_to_tgw" {
  for_each = module.hub_vpc.firewall_route_table_ids

  route_table_id         = each.value
  destination_cidr_block = var.spoke_cidr_supernet
  transit_gateway_id     = module.transit_gateway[0].transit_gateway_id
}

# ── 5. Egress subnets → Firewall (internet return traffic) ────────────────────
# Return traffic from internet (post-NAT) is directed back through the firewall
# before being forwarded to TGW → spoke.
resource "aws_route" "egress_return_to_firewall" {
  for_each = module.hub_vpc.egress_route_table_ids

  route_table_id         = each.value
  destination_cidr_block = var.spoke_cidr_supernet
  vpc_endpoint_id        = local.firewall_endpoint_ids[each.key]
}

# ── 6. Endpoint subnets → Firewall (endpoint return traffic) ──────────────────
# Responses from interface endpoints back to spokes pass through the firewall
# before returning via TGW. Symmetric with route 2 — the firewall sees both
# the initial request and the response, keeping stateful tracking intact.
resource "aws_route" "endpoint_return_to_firewall" {
  for_each = module.hub_vpc.endpoint_route_table_ids

  route_table_id         = each.value
  destination_cidr_block = var.spoke_cidr_supernet
  vpc_endpoint_id        = local.firewall_endpoint_ids[each.key]
}
