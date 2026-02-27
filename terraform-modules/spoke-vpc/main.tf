################################################################################
# Data Sources
################################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

################################################################################
# VPC
################################################################################

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-vpc"
    }
  )
}

################################################################################
# Subnets (one per tier × AZ combination)
################################################################################

resource "aws_subnet" "this" {
  for_each = local.subnet_map

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.name}-${each.key}"
      Tier    = each.value.tier_name
      Purpose = each.value.tier_name
    }
  )
}

################################################################################
# Route Tables (one per tier × AZ combination)
################################################################################

resource "aws_route_table" "this" {
  for_each = local.subnet_map

  vpc_id = aws_vpc.this.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-${each.key}-rt"
    }
  )
}

resource "aws_route_table_association" "this" {
  for_each = local.subnet_map

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.this[each.key].id
}

################################################################################
# Transit Gateway VPC Attachment
################################################################################

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  count = local.create_tgw_attachment ? 1 : 0

  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.this.id
  subnet_ids         = local.tgw_attachment_subnet_ids

  appliance_mode_support                          = "disable"
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-tgw-attachment"
    }
  )
}

################################################################################
# Default Routes → TGW (all route tables when TGW attachment exists)
################################################################################

resource "aws_route" "default_to_tgw" {
  for_each = local.create_tgw_attachment ? local.subnet_map : {}

  route_table_id         = aws_route_table.this[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id

  depends_on = [aws_ec2_transit_gateway_vpc_attachment.this]
}

################################################################################
# TGW Route Table Wiring (optional; requires hub-account permissions)
################################################################################

# Associate spoke attachment with the correct per-environment TGW route table
resource "aws_ec2_transit_gateway_route_table_association" "spoke_env" {
  count = local.enable_tgw_rt_wiring ? 1 : 0

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id = local.environment_route_table_id
}

# Propagate spoke CIDR into the inspection (firewall) route table
resource "aws_ec2_transit_gateway_route_table_propagation" "to_inspection" {
  count = local.enable_tgw_rt_wiring ? 1 : 0

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id = var.inspection_route_table_id
}

# Propagate spoke CIDR into the shared services route table (optional)
resource "aws_ec2_transit_gateway_route_table_propagation" "to_shared_services" {
  count = local.enable_shared_svc_prop ? 1 : 0

  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this[0].id
  transit_gateway_route_table_id = var.shared_services_route_table_id
}
