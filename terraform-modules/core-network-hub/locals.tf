locals {
  # Common tags applied to all resources via child modules
  common_tags = merge(
    var.tags,
    {
      Environment   = var.environment
      ManagedBy     = "terraform"
      Module        = "core-network-hub"
      ModuleVersion = local.module_version
    }
  )

  # Collect all route table IDs for gateway endpoints (primary region)
  # Gateway endpoints need route tables from all subnet tiers that require S3/DynamoDB access
  primary_gateway_endpoint_route_table_ids = concat(
    values(module.hub_vpc.endpoint_route_table_ids),
    values(module.hub_vpc.egress_route_table_ids),
    values(module.hub_vpc.tgw_attachment_route_table_ids),
    values(module.hub_vpc.firewall_route_table_ids)
  )

  # Collect all route table IDs for gateway endpoints (DR region)
  dr_gateway_endpoint_route_table_ids = var.dr_enabled ? concat(
    values(module.hub_vpc.dr_endpoint_route_table_ids),
    values(module.hub_vpc.dr_egress_route_table_ids),
    values(module.hub_vpc.dr_tgw_attachment_route_table_ids),
    values(module.hub_vpc.dr_firewall_route_table_ids)
  ) : []
}
