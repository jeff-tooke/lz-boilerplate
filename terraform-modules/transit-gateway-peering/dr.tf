################################################################################
# DR Region Provider
################################################################################

provider "aws" {
  alias  = "dr"
  region = var.secondary_region
}

################################################################################
# DR Transit Gateway Peering Attachment
################################################################################

resource "aws_ec2_transit_gateway_peering_attachment" "dr" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr

  transit_gateway_id      = var.dr_transit_gateway_id
  peer_transit_gateway_id = var.dr_peer_transit_gateway_id
  peer_account_id         = local.peer_account_id
  peer_region             = var.secondary_region

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-tgw-peering-dr"
      Region = "dr"
    }
  )
}

################################################################################
# DR Accept the Peering Attachment
################################################################################

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "dr" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr

  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.dr[0].id

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-tgw-peering-accepter-dr"
      Region = "dr"
    }
  )
}

################################################################################
# DR Static Routes (Requester Side)
################################################################################

resource "aws_ec2_transit_gateway_route" "dr_requester" {
  for_each = local.dr_requester_route_map
  provider = aws.dr

  destination_cidr_block         = each.value
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.dr[0].id
  transit_gateway_route_table_id = var.dr_requester_route_table_id
}

################################################################################
# DR Static Routes (Accepter Side)
################################################################################

resource "aws_ec2_transit_gateway_route" "dr_accepter" {
  for_each = local.dr_accepter_route_map
  provider = aws.dr

  destination_cidr_block         = each.value
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.dr[0].id
  transit_gateway_route_table_id = var.dr_accepter_route_table_id
}
