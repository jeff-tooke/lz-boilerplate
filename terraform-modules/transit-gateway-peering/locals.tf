locals {
  # Common tags applied to all resources
  common_tags = merge(
    var.tags,
    {
      Environment   = var.environment
      ManagedBy     = "terraform"
      Module        = "transit-gateway-peering"
      ModuleVersion = local.module_version
    }
  )

  # Resolve peer account ID (default to current account for same-account peering)
  peer_account_id = var.peer_account_id != null ? var.peer_account_id : data.aws_caller_identity.current.account_id

  # Build route maps for for_each
  requester_route_map = var.requester_route_table_id != "" ? {
    for cidr in var.requester_routes : cidr => cidr
  } : {}

  accepter_route_map = var.accepter_route_table_id != "" ? {
    for cidr in var.accepter_routes : cidr => cidr
  } : {}

  dr_requester_route_map = var.dr_enabled && var.dr_requester_route_table_id != "" ? {
    for cidr in var.dr_requester_routes : cidr => cidr
  } : {}

  dr_accepter_route_map = var.dr_enabled && var.dr_accepter_route_table_id != "" ? {
    for cidr in var.dr_accepter_routes : cidr => cidr
  } : {}
}
