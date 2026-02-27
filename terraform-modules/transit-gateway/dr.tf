################################################################################
# DR Region Provider
################################################################################

provider "aws" {
  alias  = "dr"
  region = var.secondary_region
}

################################################################################
# DR Transit Gateway
################################################################################

resource "aws_ec2_transit_gateway" "dr" {
  count    = local.dr_create_tgw ? 1 : 0
  provider = aws.dr

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
      Name   = "${var.name}-tgw-dr"
      Region = "dr"
    }
  )
}

################################################################################
# DR Transit Gateway VPC Attachment (DR Hub VPC)
################################################################################

resource "aws_ec2_transit_gateway_vpc_attachment" "dr" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr

  transit_gateway_id = local.dr_transit_gateway_id
  vpc_id             = var.dr_vpc_id
  subnet_ids         = var.dr_subnet_ids

  appliance_mode_support                          = var.appliance_mode_support
  transit_gateway_default_route_table_association = local.effective_hub_default_rt_association
  transit_gateway_default_route_table_propagation = local.effective_hub_default_rt_propagation

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-hub-vpc-attachment-dr"
      Region = "dr"
    }
  )
}

################################################################################
# DR RAM Resource Share
################################################################################

resource "aws_ram_resource_share" "dr_tgw" {
  count    = var.dr_enabled && var.share_transit_gateway ? 1 : 0
  provider = aws.dr

  name                      = "${var.name}-tgw-share-dr"
  allow_external_principals = var.ram_allow_external_principals

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-tgw-share-dr"
      Region = "dr"
    }
  )
}

resource "aws_ram_resource_association" "dr_tgw" {
  count    = var.dr_enabled && var.share_transit_gateway ? 1 : 0
  provider = aws.dr

  resource_arn       = local.dr_create_tgw ? aws_ec2_transit_gateway.dr[0].arn : "arn:aws:ec2:${var.secondary_region}:${data.aws_caller_identity.current.account_id}:transit-gateway/${var.dr_transit_gateway_id}"
  resource_share_arn = aws_ram_resource_share.dr_tgw[0].arn
}

resource "aws_ram_principal_association" "dr_tgw" {
  count    = var.dr_enabled && var.share_transit_gateway ? length(var.ram_principals) : 0
  provider = aws.dr

  principal          = var.ram_principals[count.index]
  resource_share_arn = aws_ram_resource_share.dr_tgw[0].arn
}

################################################################################
# DR Per-Environment TGW Route Tables
# Mirror of primary region resources — only created when dr_enabled = true and
# create_environment_route_tables = true with a non-empty environments list
################################################################################

resource "aws_ec2_transit_gateway_route_table" "inspection_dr" {
  count    = var.dr_enabled && local.create_env_rts ? 1 : 0
  provider = aws.dr

  transit_gateway_id = local.dr_transit_gateway_id

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-tgw-rt-inspection-dr"
      Region = "dr"
    }
  )
}

resource "aws_ec2_transit_gateway_route_table" "environment_dr" {
  for_each = var.dr_enabled && local.create_env_rts ? toset(var.environments) : toset([])
  provider = aws.dr

  transit_gateway_id = local.dr_transit_gateway_id

  tags = merge(
    local.common_tags,
    {
      Name        = "${var.name}-tgw-rt-${each.key}-dr"
      Region      = "dr"
      Environment = each.key
    }
  )
}

resource "aws_ec2_transit_gateway_route_table" "shared_services_dr" {
  count    = var.dr_enabled && local.create_env_rts && var.create_shared_services_route_table ? 1 : 0
  provider = aws.dr

  transit_gateway_id = local.dr_transit_gateway_id

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-tgw-rt-shared-services-dr"
      Region = "dr"
    }
  )
}

# Associate DR hub attachment with the DR inspection route table
resource "aws_ec2_transit_gateway_route_table_association" "inspection_hub_dr" {
  count    = var.dr_enabled && local.create_env_rts ? 1 : 0
  provider = aws.dr

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dr[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.inspection_dr[0].id
}

# Propagate DR hub attachment CIDR into each DR environment route table
resource "aws_ec2_transit_gateway_route_table_propagation" "env_from_hub_dr" {
  for_each = var.dr_enabled && local.create_env_rts ? toset(var.environments) : toset([])
  provider = aws.dr

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dr[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.environment_dr[each.key].id
}

# Propagate DR hub attachment CIDR into DR shared services route table
resource "aws_ec2_transit_gateway_route_table_propagation" "shared_services_from_hub_dr" {
  count    = var.dr_enabled && local.create_env_rts && var.create_shared_services_route_table ? 1 : 0
  provider = aws.dr

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dr[0].id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_services_dr[0].id
}

# Default route in each DR environment route table — all traffic to inspection
resource "aws_ec2_transit_gateway_route" "env_default_dr" {
  for_each = var.dr_enabled && local.create_env_rts ? toset(var.environments) : toset([])
  provider = aws.dr

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.environment_dr[each.key].id
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dr[0].id
}

# Default route in DR shared services route table — all traffic to inspection
resource "aws_ec2_transit_gateway_route" "shared_services_default_dr" {
  count    = var.dr_enabled && local.create_env_rts && var.create_shared_services_route_table ? 1 : 0
  provider = aws.dr

  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.shared_services_dr[0].id
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.dr[0].id
}
