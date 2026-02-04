data "aws_region" "current" {}

locals {
  # Resolve target region from primary/secondary selection
  selected_region = var.target_region == "primary" ? var.primary_region : var.secondary_region
  region          = coalesce(local.selected_region, data.aws_region.current.name)

  # Common Control Tower control identifiers (partial list - extend as needed)
  # Full catalog: https://docs.aws.amazon.com/controltower/latest/controlreference/control-identifiers.html
  control_catalog = {
    # Data residency controls
    disallow_vpc_internet_access     = "AWS-GR_DISALLOW_VPC_INTERNET_ACCESS"
    disallow_cross_region_networking = "AWS-GR_DISALLOW_CROSS_REGION_NETWORKING"

    # Security controls
    require_imdsv2            = "AWS-GR_EC2_INSTANCE_NO_PUBLIC_IP"
    disallow_public_s3        = "AWS-GR_S3_BUCKET_PUBLIC_READ_PROHIBITED"
    require_s3_encryption     = "AWS-GR_S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
    require_rds_encryption    = "AWS-GR_RDS_INSTANCE_PUBLIC_ACCESS_CHECK"
    require_ebs_encryption    = "AWS-GR_ENCRYPTED_VOLUMES"
    require_root_mfa          = "AWS-GR_ROOT_ACCOUNT_MFA_ENABLED"
    disallow_root_access_keys = "AWS-GR_RESTRICT_ROOT_USER_ACCESS_KEYS"

    # Logging controls
    require_cloudtrail_enabled        = "AWS-GR_CLOUDTRAIL_ENABLED"
    require_cloudwatch_log_encryption = "AWS-GR_CLOUDWATCH_LOG_GROUP_ENCRYPTED"

    # Network controls
    disallow_public_ip_on_ec2 = "AWS-GR_EC2_INSTANCE_NO_PUBLIC_IP_CHECK"
    require_vpc_flow_logs     = "AWS-GR_VPC_FLOW_LOGS_ENABLED"
  }

  # Build control ARN from identifier
  # Format: arn:aws:controltower:{region}::control/{identifier}
  control_arns = {
    for key, identifier in local.control_catalog :
    key => "arn:aws:controltower:${local.region}::control/${identifier}"
  }

  # Merge catalog controls with custom controls
  all_controls = merge(local.control_arns, var.custom_controls)

  # Build list of control-to-OU mappings
  control_mappings = flatten([
    for control_key in var.enabled_controls : [
      for ou_arn in var.target_ou_arns : {
        key         = "${control_key}-${md5(ou_arn)}"
        control_arn = lookup(local.all_controls, control_key, control_key)
        ou_arn      = ou_arn
      }
    ]
    if contains(keys(local.all_controls), control_key) || startswith(control_key, "arn:aws:controltower")
  ])
}

resource "aws_controltower_control" "this" {
  for_each = { for mapping in local.control_mappings : mapping.key => mapping }

  control_identifier = each.value.control_arn
  target_identifier  = each.value.ou_arn

  dynamic "parameters" {
    for_each = lookup(var.control_parameters, split("-", each.key)[0], [])
    content {
      key   = parameters.value.key
      value = parameters.value.value
    }
  }
}
