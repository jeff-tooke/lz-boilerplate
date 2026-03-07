################################################################################
# Data Sources
################################################################################

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}

# Only called when enable_s3_endpoint = true and organization_id is not set
data "aws_organizations_organization" "current" {
  count = local.lookup_org_id ? 1 : 0
}

# Discovers all FORWARD resolver rules shared with this account via RAM
data "aws_route53_resolver_rules" "shared_forward" {
  count        = local.associate_resolver_rules ? 1 : 0
  rule_type    = "FORWARD"
  share_status = "SHARED_WITH_ME"
}

# Look up individual rule details so we can filter by domain_name
data "aws_route53_resolver_rule" "shared_forward" {
  for_each         = local.associate_resolver_rules ? toset(data.aws_route53_resolver_rules.shared_forward[0].resolver_rule_ids) : toset([])
  resolver_rule_id = each.value
}

data "aws_iam_policy_document" "dynamodb_endpoint" {
  count = local.create_dynamodb_endpoint ? 1 : 0

  statement {
    sid       = "RestrictToOrganisation"
    effect    = "Allow"
    actions   = ["dynamodb:*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceOrgID"
      values   = [local.effective_org_id]
    }
  }
}

data "aws_iam_policy_document" "s3_endpoint" {
  count = local.create_s3_endpoint ? 1 : 0

  statement {
    sid       = "RestrictToOrganisation"
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceOrgID"
      values   = [local.effective_org_id]
    }
  }
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

################################################################################
# Route53 Resolver Rule Associations (optional)
################################################################################

resource "aws_route53_resolver_rule_association" "shared_forward" {
  for_each = local.resolver_rules_to_associate

  resolver_rule_id = each.value
  vpc_id           = aws_vpc.this.id
  name             = "${var.name}-resolver-${each.value}"
}

################################################################################
# DynamoDB Gateway Endpoint (optional)
################################################################################

resource "aws_vpc_endpoint" "dynamodb" {
  count = local.create_dynamodb_endpoint ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.dynamodb"
  vpc_endpoint_type = "Gateway"

  # Exclude TGW attachment subnet route tables (first tier) when TGW is present,
  # to avoid injecting DynamoDB routes into TGW ENI subnets.
  route_table_ids = [
    for k, rt in aws_route_table.this : rt.id
    if !local.create_tgw_attachment || !contains(local.tgw_subnet_rt_keys, k)
  ]

  policy = data.aws_iam_policy_document.dynamodb_endpoint[0].json

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-dynamodb-endpoint"
    }
  )
}

################################################################################
# S3 Gateway Endpoint (optional)
################################################################################

resource "aws_vpc_endpoint" "s3" {
  count = local.create_s3_endpoint ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  # Exclude TGW attachment subnet route tables (first tier) when TGW is present,
  # to avoid injecting S3 routes into TGW ENI subnets.
  route_table_ids = [
    for k, rt in aws_route_table.this : rt.id
    if !local.create_tgw_attachment || !contains(local.tgw_subnet_rt_keys, k)
  ]

  policy = data.aws_iam_policy_document.s3_endpoint[0].json

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-s3-endpoint"
    }
  )
}
