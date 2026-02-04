################################################################################
# Primary Region VPC
################################################################################

resource "aws_vpc" "primary" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-hub-vpc"
    }
  )
}

resource "aws_internet_gateway" "primary" {
  vpc_id = aws_vpc.primary.id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-igw"
    }
  )
}

################################################################################
# Primary Region - Firewall Subnets (/28)
################################################################################

resource "aws_subnet" "firewall" {
  for_each = local.firewall_subnets

  vpc_id            = aws_vpc.primary.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(
    local.common_tags,
    {
      Name    = each.value.name
      Purpose = "firewall"
      Tier    = "firewall"
    }
  )
}

resource "aws_route_table" "firewall" {
  for_each = local.firewall_subnets

  vpc_id = aws_vpc.primary.id

  tags = merge(
    local.common_tags,
    {
      Name = "${each.value.name}-rt"
    }
  )
}

resource "aws_route_table_association" "firewall" {
  for_each = local.firewall_subnets

  subnet_id      = aws_subnet.firewall[each.key].id
  route_table_id = aws_route_table.firewall[each.key].id
}

################################################################################
# Primary Region - Transit Gateway Attachment Subnets (/28)
################################################################################

resource "aws_subnet" "tgw_attachment" {
  for_each = local.tgw_attachment_subnets

  vpc_id            = aws_vpc.primary.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(
    local.common_tags,
    {
      Name    = each.value.name
      Purpose = "transit-gateway-attachment"
      Tier    = "tgw"
    }
  )
}

resource "aws_route_table" "tgw_attachment" {
  for_each = local.tgw_attachment_subnets

  vpc_id = aws_vpc.primary.id

  tags = merge(
    local.common_tags,
    {
      Name = "${each.value.name}-rt"
    }
  )
}

resource "aws_route_table_association" "tgw_attachment" {
  for_each = local.tgw_attachment_subnets

  subnet_id      = aws_subnet.tgw_attachment[each.key].id
  route_table_id = aws_route_table.tgw_attachment[each.key].id
}

################################################################################
# Primary Region - Egress/NAT Gateway Subnets (/28)
################################################################################

resource "aws_subnet" "egress" {
  for_each = local.egress_subnets

  vpc_id            = aws_vpc.primary.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(
    local.common_tags,
    {
      Name    = each.value.name
      Purpose = "egress-nat-gateway"
      Tier    = "egress"
    }
  )
}

resource "aws_route_table" "egress" {
  for_each = local.egress_subnets

  vpc_id = aws_vpc.primary.id

  tags = merge(
    local.common_tags,
    {
      Name = "${each.value.name}-rt"
    }
  )
}

resource "aws_route" "egress_to_igw" {
  for_each = local.egress_subnets

  route_table_id         = aws_route_table.egress[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.primary.id
}

resource "aws_route_table_association" "egress" {
  for_each = local.egress_subnets

  subnet_id      = aws_subnet.egress[each.key].id
  route_table_id = aws_route_table.egress[each.key].id
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  for_each = local.egress_subnets

  domain = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-nat-eip-${each.key}"
    }
  )

  depends_on = [aws_internet_gateway.primary]
}

# NAT Gateways (one per AZ for HA)
resource "aws_nat_gateway" "primary" {
  for_each = local.egress_subnets

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.egress[each.key].id

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-nat-${each.key}"
    }
  )

  depends_on = [aws_internet_gateway.primary]
}

################################################################################
# Primary Region - VPC Endpoint Subnets (/25)
################################################################################

resource "aws_subnet" "endpoints" {
  for_each = local.endpoint_subnets

  vpc_id            = aws_vpc.primary.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = merge(
    local.common_tags,
    {
      Name    = each.value.name
      Purpose = "vpc-endpoints"
      Tier    = "endpoints"
    }
  )
}

resource "aws_route_table" "endpoints" {
  for_each = local.endpoint_subnets

  vpc_id = aws_vpc.primary.id

  tags = merge(
    local.common_tags,
    {
      Name = "${each.value.name}-rt"
    }
  )
}

resource "aws_route_table_association" "endpoints" {
  for_each = local.endpoint_subnets

  subnet_id      = aws_subnet.endpoints[each.key].id
  route_table_id = aws_route_table.endpoints[each.key].id
}

################################################################################
# Primary Region - VPC Flow Logs
################################################################################

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc-flow-logs/${var.name}-hub-vpc"
  retention_in_days = 30

  tags = local.common_tags
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.name}-vpc-flow-logs-role"

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

  tags = local.common_tags
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  name = "${var.name}-vpc-flow-logs-policy"
  role = aws_iam_role.vpc_flow_logs.id

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

resource "aws_flow_log" "primary" {
  vpc_id                   = aws_vpc.primary.id
  traffic_type             = "ALL"
  log_destination_type     = "cloud-watch-logs"
  log_destination          = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn             = aws_iam_role.vpc_flow_logs.arn
  max_aggregation_interval = 60

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-vpc-flow-log"
    }
  )
}
