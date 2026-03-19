locals {
  common_tags = merge(
    var.tags,
    {
      Environment   = var.environment
      ManagedBy     = "terraform"
      Module        = "workload-asg"
      ModuleVersion = local.module_version
    }
  )

  backup_tags = var.backup_enabled ? {
    backup_enabled   = "true"
    backup_retention = tostring(var.backup_retention_days)
  } : {}

  ################################################################################
  # Instance Type Defaults
  ################################################################################

  default_instance_types = {
    dev     = "t3.micro"
    test    = "t3.micro"
    preprod = "t3.micro"
    prod    = "t3.small"
  }

  effective_instance_type = var.instance_type != null ? var.instance_type : local.default_instance_types[var.environment]

  ################################################################################
  # OS / AMI Selection
  ################################################################################

  is_windows = var.os == "windows"
  ami_id     = local.is_windows ? data.aws_ami.windows.id : data.aws_ami.amazon_linux.id

  ################################################################################
  # Userdata
  ################################################################################

  userdata = local.is_windows ? (
    base64encode(file("${path.module}/templates/windows_userdata.ps1"))
  ) : (
    base64encode(file("${path.module}/templates/linux_userdata.sh"))
  )

  ################################################################################
  # ASG Health / Timing
  ################################################################################

  health_check_type         = var.create_alb ? "ELB" : "EC2"
  health_check_grace_period = local.is_windows ? 600 : 120
  effective_desired_capacity = var.desired_capacity != null ? var.desired_capacity : var.min_size
}
