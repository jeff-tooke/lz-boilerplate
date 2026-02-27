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
  # Gateway endpoints are VPC-local only — TGW and firewall subnets deliberately excluded
  # to avoid silently dropping spoke traffic destined for S3/DynamoDB via TGW.
  primary_gateway_endpoint_route_table_ids = concat(
    values(module.hub_vpc.endpoint_route_table_ids),
    values(module.hub_vpc.egress_route_table_ids)
  )

  # Collect all route table IDs for gateway endpoints (DR region)
  dr_gateway_endpoint_route_table_ids = var.dr_enabled ? concat(
    values(module.hub_vpc.dr_endpoint_route_table_ids),
    values(module.hub_vpc.dr_egress_route_table_ids)
  ) : []

  ################################################################################
  # Endpoint Policies
  # When an explicit policy is provided, use it.
  # When only aws_organization_id is provided, generate org-boundary defaults.
  # When neither is provided, pass null → AWS-managed default (allow all).
  ################################################################################

  _org_interface_policy = var.aws_organization_id != "" ? jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowOrgPrincipalsOnly"
      Effect    = "Allow"
      Principal = "*"
      Action    = "*"
      Resource  = "*"
      Condition = {
        StringEquals = {
          "aws:PrincipalOrgID" = var.aws_organization_id
        }
      }
    }]
  }) : null

  _org_gateway_policy = var.aws_organization_id != "" ? jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowOrgResourcesOnly"
      Effect    = "Allow"
      Principal = "*"
      Action    = "*"
      Resource  = "*"
      Condition = {
        StringEquals = {
          "aws:ResourceOrgID" = var.aws_organization_id
        }
      }
    }]
  }) : null

  effective_interface_endpoint_policy = var.interface_endpoint_policy != null ? var.interface_endpoint_policy : local._org_interface_policy
  effective_gateway_endpoint_policy   = var.gateway_endpoint_policy != null ? var.gateway_endpoint_policy : local._org_gateway_policy

  ################################################################################
  # Firewall Routing Locals
  ################################################################################

  # AZ → firewall endpoint ID, sourced from the network-firewall module output.
  # one() is used defensively; in practice the firewall is always enabled.
  firewall_endpoint_ids = one(module.network_firewall[*].firewall_endpoint_ids)

  # Cross-product of (TGW attachment AZ → RT ID) × (endpoint subnet CIDRs).
  # Produces one entry per (AZ, endpoint subnet) pair — 9 entries in a 3-AZ
  # deployment — used to create routes that override the VPC local route for
  # endpoint-bound traffic and force it through the per-AZ firewall endpoint.
  tgw_to_endpoint_routes = {
    for pair in setproduct(
      keys(module.hub_vpc.tgw_attachment_route_table_ids),
      var.endpoint_subnet_cidrs
    ) : "${pair[0]}/${pair[1]}" => {
      az            = pair[0]
      endpoint_cidr = pair[1]
      rt_id         = module.hub_vpc.tgw_attachment_route_table_ids[pair[0]]
    }
  }
}
