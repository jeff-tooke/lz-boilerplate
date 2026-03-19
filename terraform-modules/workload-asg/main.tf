################################################################################
# AMI Data Sources (both always fetched; local ternary selects the active one)
################################################################################

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ami" "windows" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

################################################################################
# IAM Instance Profile (SSM Session Manager — no inbound SSH/RDP port needed)
################################################################################

resource "aws_iam_role" "instances" {
  name = "${var.name}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instances.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instances" {
  name = "${var.name}-instance-profile"
  role = aws_iam_role.instances.name

  tags = local.common_tags
}

################################################################################
# Security Groups
################################################################################

resource "aws_security_group" "instances" {
  name        = "${var.name}-asg-sg"
  description = "Instance security group for ${var.name} ASG"
  vpc_id      = var.vpc_id

  tags = merge(local.common_tags, { Name = "${var.name}-asg-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

# Allow inbound port 80 from ALB when ALB is enabled
resource "aws_vpc_security_group_ingress_rule" "instances_from_alb" {
  count = var.create_alb ? 1 : 0

  security_group_id            = aws_security_group.instances.id
  referenced_security_group_id = aws_security_group.alb[0].id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
  description                  = "Allow HTTP from ALB"

  tags = local.common_tags
}

# Allow inbound port 80 from CIDRs when ALB is disabled (one rule per CIDR)
resource "aws_vpc_security_group_ingress_rule" "instances_from_cidrs" {
  for_each = var.create_alb ? toset([]) : toset(var.allowed_ingress_cidrs)

  security_group_id = aws_security_group.instances.id
  cidr_ipv4         = each.value
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "Allow HTTP from ${each.value}"

  tags = local.common_tags
}

resource "aws_vpc_security_group_egress_rule" "instances_all" {
  security_group_id = aws_security_group.instances.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"

  tags = local.common_tags
}

################################################################################
# Launch Template
################################################################################

resource "aws_launch_template" "this" {
  name        = "${var.name}-lt"
  description = "Launch template for ${var.name} (${var.os}, ${var.environment})"
  image_id    = local.ami_id

  instance_type = local.effective_instance_type

  user_data = local.userdata

  iam_instance_profile {
    name = aws_iam_instance_profile.instances.name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.instances.id]
    delete_on_termination       = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  block_device_mappings {
    device_name = local.is_windows ? "/dev/sda1" : "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size_gb
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  dynamic "block_device_mappings" {
    for_each = var.create_data_volume ? [1] : []
    content {
      device_name = "/dev/sdb"

      ebs {
        volume_size           = var.data_volume_size_gb
        volume_type           = "gp3"
        encrypted             = true
        delete_on_termination = true
      }
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.common_tags,
      local.backup_tags,
      { Name = "${var.name}-instance" }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      local.common_tags,
      local.backup_tags,
      { backup_type = "root" }
    )
  }

  dynamic "tag_specifications" {
    for_each = var.create_data_volume ? [1] : []
    content {
      resource_type = "volume"
      tags = merge(
        local.common_tags,
        local.backup_tags,
        { backup_type = "data" }
      )
    }
  }

  tags = merge(local.common_tags, { Name = "${var.name}-lt" })

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Auto Scaling Group
################################################################################

resource "aws_autoscaling_group" "this" {
  name                = "${var.name}-asg"
  vpc_zone_identifier = var.subnet_ids

  min_size         = var.min_size
  max_size         = var.max_size
  desired_capacity = local.effective_desired_capacity

  health_check_type         = local.health_check_type
  health_check_grace_period = local.health_check_grace_period

  target_group_arns = var.create_alb ? [aws_lb_target_group.this[0].arn] : []

  launch_template {
    id      = aws_launch_template.this.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  dynamic "tag" {
    for_each = merge(local.common_tags, { Name = "${var.name}-asg" })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}
