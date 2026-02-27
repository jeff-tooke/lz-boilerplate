# Get VPC CIDR for default security group rules
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Default security group for interface endpoints
resource "aws_security_group" "endpoint" {
  count = var.create_default_security_group && length(var.security_group_ids) == 0 && length(local.interface_endpoints) > 0 ? 1 : 0

  name_prefix = "vpc-endpoints-"
  description = "Security group for VPC interface endpoints"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from hub VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  dynamic "ingress" {
    for_each = var.spoke_cidr_supernet != "" ? [var.spoke_cidr_supernet] : []
    content {
      description = "HTTPS from spoke VPC supernet"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
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
      Name = "vpc-endpoints-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Gateway endpoints (S3, DynamoDB)
resource "aws_vpc_endpoint" "gateway" {
  for_each = toset(local.gateway_endpoints)

  vpc_id            = var.vpc_id
  service_name      = each.value
  vpc_endpoint_type = "Gateway"
  route_table_ids   = var.route_table_ids
  policy            = var.gateway_endpoint_policy

  tags = merge(
    local.common_tags,
    lookup(var.endpoint_tags, each.value, {}),
    {
      Name = "vpce-${local.endpoint_service_names[each.value]}"
    }
  )
}

# Interface endpoints (all other services)
resource "aws_vpc_endpoint" "interface" {
  for_each = toset(local.interface_endpoints)

  vpc_id              = var.vpc_id
  service_name        = each.value
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.subnet_ids
  security_group_ids  = local.security_group_ids
  private_dns_enabled = var.private_dns_enabled
  policy              = var.interface_endpoint_policy

  tags = merge(
    local.common_tags,
    lookup(var.endpoint_tags, each.value, {}),
    {
      Name = "vpce-${local.endpoint_service_names[each.value]}"
    }
  )
}
