################################################################################
# Transit Gateway
# Creates or references an existing Transit Gateway
################################################################################

resource "aws_ec2_transit_gateway" "this" {
  count = local.create_tgw ? 1 : 0

  amazon_side_asn                 = var.amazon_side_asn
  auto_accept_shared_attachments  = var.auto_accept_shared_attachments
  default_route_table_association = local.effective_default_route_table_association
  default_route_table_propagation = local.effective_default_route_table_propagation
  dns_support                     = var.dns_support
  vpn_ecmp_support                = var.vpn_ecmp_support
  multicast_support               = var.multicast_support

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-tgw"
      Region = "primary"
    }
  )
}

################################################################################
# Transit Gateway VPC Attachment (Hub VPC)
################################################################################

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  transit_gateway_id = local.transit_gateway_id
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids

  appliance_mode_support                          = var.appliance_mode_support
  transit_gateway_default_route_table_association = local.effective_hub_default_rt_association
  transit_gateway_default_route_table_propagation = local.effective_hub_default_rt_propagation

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-hub-vpc-attachment"
      Region = "primary"
    }
  )
}

################################################################################
# RAM Resource Share
# Shares the Transit Gateway with specified OUs or accounts
################################################################################

resource "aws_ram_resource_share" "tgw" {
  count = var.share_transit_gateway ? 1 : 0

  name                      = "${var.name}-tgw-share"
  allow_external_principals = var.ram_allow_external_principals

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-tgw-share"
      Region = "primary"
    }
  )
}

resource "aws_ram_resource_association" "tgw" {
  count = var.share_transit_gateway ? 1 : 0

  resource_arn       = local.create_tgw ? aws_ec2_transit_gateway.this[0].arn : "arn:aws:ec2:${var.primary_region}:${data.aws_caller_identity.current.account_id}:transit-gateway/${var.transit_gateway_id}"
  resource_share_arn = aws_ram_resource_share.tgw[0].arn
}

resource "aws_ram_principal_association" "tgw" {
  count = var.share_transit_gateway ? length(var.ram_principals) : 0

  principal          = var.ram_principals[count.index]
  resource_share_arn = aws_ram_resource_share.tgw[0].arn
}

################################################################################
# Data Sources
################################################################################

data "aws_caller_identity" "current" {}

################################################################################
# Per-Environment TGW Route Tables (Primary Region)
# Only created when create_environment_route_tables = true and environments is non-empty
################################################################################

resource "aws_ec2_transit_gateway_route_table" "inspection" {
  count = local.create_env_rts ? 1 : 0

  transit_gateway_id = local.transit_gateway_id

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-tgw-rt-inspection"
      Region = "primary"
    }
  )
}

resource "aws_ec2_transit_gateway_route_table" "environment" {
  for_each = local.create_env_rts ? toset(var.environments) : toset([])

  transit_gateway_id = local.transit_gateway_id

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name}-tgw-rt-${each.key}"
      Region      = "primary"
      Environment = each.key
    }
  )
}

resource "aws_ec2_transit_gateway_route_table" "shared_services" {
  count = local.create_env_rts && var.create_shared_services_route_table ? 1 : 0

  transit_gateway_id = local.transit_gateway_id

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-tgw-rt-shared-services"
      Region = "primary"
    }
  )
}

# Associate hub (inspection/firewall) attachment with the inspection route table
resource "aws_ec2_transit_gateway_route_table_association" "inspection_hub" {
  count = local.create_env_rts ? 1 : 0

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection[0].id
}

# Propagate hub attachment CIDR into each environment route table so return
# traffic from the inspection VPC can reach the originating spoke
resource "aws_ec2_transit_gateway_route_table_propagation" "env_from_hub" {
  for_each = local.create_env_rts ? toset(var.environments) : toset([])

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.environment[each.key].id
}

# Propagate hub attachment CIDR into shared services route table
resource "aws_ec2_transit_gateway_route_table_propagation" "shared_services_from_hub" {
  count = local.create_env_rts && var.create_shared_services_route_table ? 1 : 0

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_services[0].id
}

# Default route in each environment route table — all traffic goes to the
# inspection (hub/firewall) attachment for policy enforcement
resource "aws_ec2_transit_gateway_route" "env_default" {
  for_each = local.create_env_rts ? toset(var.environments) : toset([])

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.environment[each.key].id
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this.id
}

# Default route in shared services route table — all traffic goes to the
# inspection (hub/firewall) attachment for policy enforcement
resource "aws_ec2_transit_gateway_route" "shared_services_default" {
  count = local.create_env_rts && var.create_shared_services_route_table ? 1 : 0

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_services[0].id
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this.id
}
