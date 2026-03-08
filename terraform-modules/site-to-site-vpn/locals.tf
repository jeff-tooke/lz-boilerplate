locals {
  common_tags = merge(
    var.tags,
    {
      Environment   = var.environment
      ManagedBy     = "terraform"
      Module        = "site-to-site-vpn"
      ModuleVersion = local.module_version
    }
  )

  # Only enabled connections create resources. Disabled connections can remain
  # in config (e.g. during decommissioning) without causing resource drift.
  active_vpn_connections = { for k, v in var.vpn_connections : k => v if v.enabled }

  # Cross-product of active VPN connections × environment route tables.
  # Drives the vpn_to_env propagation for_each.
  vpn_to_env_propagations = {
    for pair in setproduct(keys(local.active_vpn_connections), keys(var.environment_route_table_ids)) :
    "${pair[0]}/${pair[1]}" => {
      conn_key = pair[0]
      env_key  = pair[1]
    }
  }

  # Connection keys to propagate into shared services RT (empty when no RT provided).
  vpn_to_shared_services = var.shared_services_route_table_id != "" ? keys(local.active_vpn_connections) : []

  # DR cross-product and shared services list (parallel to primary above).
  dr_vpn_to_env_propagations = {
    for pair in setproduct(keys(local.active_vpn_connections), keys(var.dr_environment_route_table_ids)) :
    "${pair[0]}/${pair[1]}" => {
      conn_key = pair[0]
      env_key  = pair[1]
    }
  }

  dr_vpn_to_shared_services = var.dr_shared_services_route_table_id != "" ? keys(local.active_vpn_connections) : []

  # Default route destination placed in vpn-rt pointing back to the hub VPC
  # attachment (firewall). When a supernet is provided, use it instead of
  # 0.0.0.0/0 to avoid a blackhole for non-spoke-destined traffic.
  default_route_cidr = var.spoke_cidr_supernet != "" ? var.spoke_cidr_supernet : "0.0.0.0/0"

  # Flattened map of static routes per VPN connection.
  # Key: "<conn_key>/<cidr>" ensures uniqueness across connections.
  # Only populated when destination_cidr_blocks is non-empty (static_routes_only = true cases).
  static_routes = {
    for pair in flatten([
      for k, v in local.active_vpn_connections : [
        for cidr in v.destination_cidr_blocks : {
          key      = "${k}/${cidr}"
          conn_key = k
          cidr     = cidr
        }
      ]
    ]) : pair.key => pair
  }
}
