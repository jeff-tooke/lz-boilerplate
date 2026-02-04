################################################################################
# DR Region Provider
################################################################################

provider "aws" {
  alias  = "dr"
  region = var.secondary_region
}

################################################################################
# DR Region VPC
################################################################################

resource "aws_vpc" "dr" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr

  cidr_block           = var.dr_vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-hub-vpc-dr"
      Region = "dr"
    }
  )
}

resource "aws_internet_gateway" "dr" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr

  vpc_id = aws_vpc.dr[0].id

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-igw-dr"
      Region = "dr"
    }
  )
}

################################################################################
# DR Region - Firewall Subnets (/28)
################################################################################

resource "aws_subnet" "dr_firewall" {
  for_each = local.dr_firewall_subnets
  provider = aws.dr

  vpc_id            = aws_vpc.dr[0].id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(
    local.common_tags,
    {
      Name    = each.value.name
      Purpose = "firewall"
      Tier    = "firewall"
      Region  = "dr"
    }
  )
}

resource "aws_route_table" "dr_firewall" {
  for_each = local.dr_firewall_subnets
  provider = aws.dr

  vpc_id = aws_vpc.dr[0].id

  tags = merge(
    local.common_tags,
    {
      Name   = "${each.value.name}-rt" # name already includes -dr suffix
      Region = "dr"
    }
  )
}

resource "aws_route_table_association" "dr_firewall" {
  for_each = local.dr_firewall_subnets
  provider = aws.dr

  subnet_id      = aws_subnet.dr_firewall[each.key].id
  route_table_id = aws_route_table.dr_firewall[each.key].id
}

################################################################################
# DR Region - Transit Gateway Attachment Subnets (/28)
################################################################################

resource "aws_subnet" "dr_tgw_attachment" {
  for_each = local.dr_tgw_attachment_subnets
  provider = aws.dr

  vpc_id            = aws_vpc.dr[0].id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(
    local.common_tags,
    {
      Name    = each.value.name
      Purpose = "transit-gateway-attachment"
      Tier    = "tgw"
      Region  = "dr"
    }
  )
}

resource "aws_route_table" "dr_tgw_attachment" {
  for_each = local.dr_tgw_attachment_subnets
  provider = aws.dr

  vpc_id = aws_vpc.dr[0].id

  tags = merge(
    local.common_tags,
    {
      Name   = "${each.value.name}-rt"
      Region = "dr"
    }
  )
}

resource "aws_route_table_association" "dr_tgw_attachment" {
  for_each = local.dr_tgw_attachment_subnets
  provider = aws.dr

  subnet_id      = aws_subnet.dr_tgw_attachment[each.key].id
  route_table_id = aws_route_table.dr_tgw_attachment[each.key].id
}

################################################################################
# DR Region - Egress/NAT Gateway Subnets (/28)
################################################################################

resource "aws_subnet" "dr_egress" {
  for_each = local.dr_egress_subnets
  provider = aws.dr

  vpc_id            = aws_vpc.dr[0].id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(
    local.common_tags,
    {
      Name    = each.value.name
      Purpose = "egress-nat-gateway"
      Tier    = "egress"
      Region  = "dr"
    }
  )
}

resource "aws_route_table" "dr_egress" {
  for_each = local.dr_egress_subnets
  provider = aws.dr

  vpc_id = aws_vpc.dr[0].id

  tags = merge(
    local.common_tags,
    {
      Name   = "${each.value.name}-rt"
      Region = "dr"
    }
  )
}

resource "aws_route" "dr_egress_to_igw" {
  for_each = local.dr_egress_subnets
  provider = aws.dr

  route_table_id         = aws_route_table.dr_egress[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.dr[0].id
}

resource "aws_route_table_association" "dr_egress" {
  for_each = local.dr_egress_subnets
  provider = aws.dr

  subnet_id      = aws_subnet.dr_egress[each.key].id
  route_table_id = aws_route_table.dr_egress[each.key].id
}

# Elastic IPs for DR NAT Gateways
resource "aws_eip" "dr_nat" {
  for_each = local.dr_egress_subnets
  provider = aws.dr

  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-nat-eip-${each.key}-dr"
      Region = "dr"
    }
  )

  depends_on = [aws_internet_gateway.dr]
}

# DR NAT Gateways (one per AZ for HA)
resource "aws_nat_gateway" "dr" {
  for_each = local.dr_egress_subnets
  provider = aws.dr

  allocation_id = aws_eip.dr_nat[each.key].id
  subnet_id     = aws_subnet.dr_egress[each.key].id

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-nat-${each.key}-dr"
      Region = "dr"
    }
  )

  depends_on = [aws_internet_gateway.dr]
}

################################################################################
# DR Region - VPC Endpoint Subnets (/25)
################################################################################

resource "aws_subnet" "dr_endpoints" {
  for_each = local.dr_endpoint_subnets
  provider = aws.dr

  vpc_id            = aws_vpc.dr[0].id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(
    local.common_tags,
    {
      Name    = each.value.name
      Purpose = "vpc-endpoints"
      Tier    = "endpoints"
      Region  = "dr"
    }
  )
}

resource "aws_route_table" "dr_endpoints" {
  for_each = local.dr_endpoint_subnets
  provider = aws.dr

  vpc_id = aws_vpc.dr[0].id

  tags = merge(
    local.common_tags,
    {
      Name   = "${each.value.name}-rt"
      Region = "dr"
    }
  )
}

resource "aws_route_table_association" "dr_endpoints" {
  for_each = local.dr_endpoint_subnets
  provider = aws.dr

  subnet_id      = aws_subnet.dr_endpoints[each.key].id
  route_table_id = aws_route_table.dr_endpoints[each.key].id
}

################################################################################
# DR Region - VPC Flow Logs
################################################################################

resource "aws_cloudwatch_log_group" "dr_vpc_flow_logs" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr

  name              = "/aws/vpc-flow-logs/${var.name}-hub-vpc-dr"
  retention_in_days = 30

  tags = merge(
    local.common_tags,
    {
      Region = "dr"
    }
  )
}

resource "aws_iam_role" "dr_vpc_flow_logs" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr

  name = "${var.name}-vpc-flow-logs-role-dr"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Region = "dr"
    }
  )
}

resource "aws_iam_role_policy" "dr_vpc_flow_logs" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr

  name = "${var.name}-vpc-flow-logs-policy-dr"
  role = aws_iam_role.dr_vpc_flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "dr" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr

  vpc_id                   = aws_vpc.dr[0].id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.dr_vpc_flow_logs[0].arn
  iam_role_arn             = aws_iam_role.dr_vpc_flow_logs[0].arn
  max_aggregation_interval = 60

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-vpc-flow-log-dr"
      Region = "dr"
    }
  )
}
