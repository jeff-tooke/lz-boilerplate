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
}
