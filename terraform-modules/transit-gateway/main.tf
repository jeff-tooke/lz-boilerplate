################################################################################
# Transit Gateway
# Creates or references an existing Transit Gateway
################################################################################

resource "aws_ec2_transit_gateway" "this" {
  count = local.create_tgw ? 1 : 0

  amazon_side_asn                 = var.amazon_side_asn
  auto_accept_shared_attachments  = var.auto_accept_shared_attachments
  default_route_table_association = var.default_route_table_association
  default_route_table_propagation = var.default_route_table_propagation
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
  transit_gateway_default_route_table_association = var.transit_gateway_default_route_table_association
  transit_gateway_default_route_table_propagation = var.transit_gateway_default_route_table_propagation

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
