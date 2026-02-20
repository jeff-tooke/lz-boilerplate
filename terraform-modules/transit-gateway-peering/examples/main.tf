################################################################################
# Example: Transit Gateway Peering (Prod <-> Nonprod)
################################################################################

# Same-region peering between prod and nonprod TGWs
module "tgw_peering_prod_nonprod" {
  source = "../"

  name        = "prod-to-nonprod"
  environment = "shared"

  # Requester: prod TGW
  transit_gateway_id = "tgw-prod-0123456789abcdef0"

  # Accepter: nonprod TGW (same region, same account)
  peer_transit_gateway_id = "tgw-nonprod-0fedcba9876543210"

  # Static routes: prod TGW learns nonprod CIDRs and vice versa
  requester_route_table_id = "tgw-rtb-prod-aaa"
  requester_routes         = ["10.1.0.0/16"] # nonprod VPC CIDR

  accepter_route_table_id = "tgw-rtb-nonprod-bbb"
  accepter_routes         = ["10.0.0.0/16"] # prod VPC CIDR

  tags = {
    Project = "network-hub"
  }
}

# Same-region peering with DR
module "tgw_peering_prod_nonprod_dr" {
  source = "../"

  name        = "prod-to-nonprod"
  environment = "shared"

  # Primary region: prod <-> nonprod
  transit_gateway_id      = "tgw-prod-0123456789abcdef0"
  peer_transit_gateway_id = "tgw-nonprod-0fedcba9876543210"

  requester_route_table_id = "tgw-rtb-prod-aaa"
  requester_routes         = ["10.1.0.0/16"]

  accepter_route_table_id = "tgw-rtb-nonprod-bbb"
  accepter_routes         = ["10.0.0.0/16"]

  # DR region: prod-dr <-> nonprod-dr
  dr_enabled                 = true
  secondary_region           = "ap-southeast-4"
  dr_transit_gateway_id      = "tgw-prod-dr-111111111"
  dr_peer_transit_gateway_id = "tgw-nonprod-dr-222222222"

  dr_requester_route_table_id = "tgw-rtb-prod-dr-ccc"
  dr_requester_routes         = ["10.3.0.0/16"]

  dr_accepter_route_table_id = "tgw-rtb-nonprod-dr-ddd"
  dr_accepter_routes         = ["10.2.0.0/16"]

  tags = {
    Project = "network-hub"
  }
}

# Minimal peering (no static routes, rely on route propagation)
module "tgw_peering_simple" {
  source = "../"

  name        = "prod-to-nonprod"
  environment = "shared"

  transit_gateway_id      = "tgw-prod-0123456789abcdef0"
  peer_transit_gateway_id = "tgw-nonprod-0fedcba9876543210"

  tags = {
    Project = "network-hub"
  }
}
