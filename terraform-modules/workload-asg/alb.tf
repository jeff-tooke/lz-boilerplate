################################################################################
# ALB Security Group (count = 0 when create_alb = false)
################################################################################

resource "aws_security_group" "alb" {
  count = var.create_alb ? 1 : 0

  name        = "${var.name}-alb-sg"
  description = "ALB security group for ${var.name}"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${var.name}-alb-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = var.create_alb ? toset(var.alb_ingress_cidrs) : toset([])

  security_group_id = aws_security_group.alb[0].id
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow HTTP from ${each.value}"

  tags = local.common_tags
}

resource "aws_vpc_security_group_egress_rule" "alb_all" {
  count = var.create_alb ? 1 : 0

  security_group_id = aws_security_group.alb[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"

  tags = local.common_tags
}

################################################################################
# Application Load Balancer
################################################################################

resource "aws_lb" "this" {
  count = var.create_alb ? 1 : 0

  name               = "${var.name}-alb"
  internal           = var.alb_internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = length(var.alb_subnet_ids) > 0 ? var.alb_subnet_ids : var.subnet_ids

  tags = merge(local.common_tags, { Name = "${var.name}-alb" })
}

resource "aws_lb_target_group" "this" {
  count = var.create_alb ? 1 : 0

  name        = "${var.name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, { Name = "${var.name}-tg" })
}

resource "aws_lb_listener" "http" {
  count = var.create_alb ? 1 : 0

  load_balancer_arn = aws_lb.this[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[0].arn
  }

  tags = merge(local.common_tags, { Name = "${var.name}-listener-http" })
}
