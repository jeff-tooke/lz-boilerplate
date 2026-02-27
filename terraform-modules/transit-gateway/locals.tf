locals {
  # Common tags applied to all resources
  common_tags = merge(
    var.tags,
    {
      Environment   = var.environment
      ManagedBy     = "terraform"
      Module        = "transit-gateway"
      ModuleVersion = local.module_version
    }
  )

  # Resolve Transit Gateway IDs
  create_tgw         = var.create_transit_gateway
  transit_gateway_id = local.create_tgw ? aws_ec2_transit_gateway.this[0].id : var.transit_gateway_id

  # DR Transit Gateway ID resolution
  dr_create_tgw         = var.dr_enabled && var.create_transit_gateway
  dr_transit_gateway_id = var.dr_enabled ? (var.create_transit_gateway ? aws_ec2_transit_gateway.dr[0].id : var.dr_transit_gateway_id) : ""

  # Environment route table feature flag
  create_env_rts = var.create_environment_route_tables && length(var.environments) > 0

  # When env RTs are active, disable default route table association/propagation on the TGW and hub attachment
  effective_default_route_table_association = local.create_env_rts ? "disable" : var.default_route_table_association
  effective_default_route_table_propagation = local.create_env_rts ? "disable" : var.default_route_table_propagation
  effective_hub_default_rt_association      = local.create_env_rts ? false : var.transit_gateway_default_route_table_association
  effective_hub_default_rt_propagation      = local.create_env_rts ? false : var.transit_gateway_default_route_table_propagation
}
