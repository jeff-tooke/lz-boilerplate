################################################################################
# DR Region Provider
################################################################################

provider "aws" {
  alias  = "dr"
  region = var.secondary_region
}

################################################################################
# DR Region - VPC Data Source
################################################################################

data "aws_vpc" "dr_selected" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr

  id = var.dr_vpc_id
}

################################################################################
# DR Region - Default Security Group
################################################################################

resource "aws_security_group" "dr_endpoint" {
  count    = var.dr_enabled && var.create_default_security_group && length(var.dr_security_group_ids) == 0 && length(local.dr_interface_endpoints) > 0 ? 1 : 0
  provider = aws.dr

  name_prefix = "vpc-endpoints-dr-"
  description = "Security group for DR VPC interface endpoints"
  vpc_id      = var.dr_vpc_id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.dr_selected[0].cidr_block]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name   = "vpc-endpoints-sg-dr"
      Region = "dr"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# DR Region - Gateway Endpoints (S3, DynamoDB)
################################################################################

resource "aws_vpc_endpoint" "dr_gateway" {
  for_each = var.dr_enabled ? toset(local.dr_gateway_endpoints) : toset([])
  provider = aws.dr

  vpc_id            = var.dr_vpc_id
  service_name      = each.value
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.dr_route_table_ids

  tags = merge(
    local.common_tags,
    lookup(var.endpoint_tags, each.value, {}),
    {
      Name   = "vpce-${local.dr_endpoint_service_names[each.value]}-dr"
      Region = "dr"
    }
  )
}

################################################################################
# DR Region - Interface Endpoints
################################################################################

resource "aws_vpc_endpoint" "dr_interface" {
  for_each = var.dr_enabled ? toset(local.dr_interface_endpoints) : toset([])
  provider = aws.dr

  vpc_id              = var.dr_vpc_id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.dr_subnet_ids
  security_group_ids  = local.dr_security_group_ids
  private_dns_enabled = var.private_dns_enabled

  tags = merge(
    local.common_tags,
    lookup(var.endpoint_tags, each.value, {}),
    {
      Name   = "vpce-${local.dr_endpoint_service_names[each.value]}-dr"
      Region = "dr"
    }
  )
}
