################################################################################
# Transit Gateway Peering Attachment
# Creates a peering between two Transit Gateways (e.g., prod <-> nonprod)
################################################################################

resource "aws_ec2_transit_gateway_peering_attachment" "this" {
  transit_gateway_id      = var.transit_gateway_id
  peer_transit_gateway_id = var.peer_transit_gateway_id
  peer_account_id         = local.peer_account_id
  peer_region             = var.peer_region

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-tgw-peering"
      Region = "primary"
    }
  )
}

################################################################################
# Accept the Peering Attachment
################################################################################

resource "aws_ec2_transit_gateway_peering_attachment_accepter" "this" {
  transit_gateway_attachment_id = aws_ec2_transit_gateway_peering_attachment.this.id

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-tgw-peering-accepter"
      Region = "primary"
    }
  )
}

################################################################################
# Static Routes (Requester Side)
# Routes traffic destined for the peer environment via the peering attachment
################################################################################

resource "aws_ec2_transit_gateway_route" "requester" {
  for_each = local.requester_route_map

  destination_cidr_block         = each.value
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.this.id
  transit_gateway_route_table_id = var.requester_route_table_id
}

################################################################################
# Static Routes (Accepter Side)
# Routes traffic destined for the requester environment via the peering attachment
################################################################################

resource "aws_ec2_transit_gateway_route" "accepter" {
  for_each = local.accepter_route_map

  destination_cidr_block         = each.value
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_peering_attachment.this.id
  transit_gateway_route_table_id = var.accepter_route_table_id
}

################################################################################
# Data Sources
################################################################################

data "aws_caller_identity" "current" {}
