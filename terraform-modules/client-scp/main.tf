locals {
  # Default admin roles that are exempt from SCPs
  admin_role_arns = length(var.admin_role_arns) > 0 ? var.admin_role_arns : ["arn:aws:iam::*:role/OrganizationAccountAccessRole"]

  # Build allowed regions list from primary/secondary or explicit list
  allowed_regions = coalesce(
    var.allowed_regions,
    compact([var.primary_region, var.secondary_region])
  )

  # Define all available SCPs with their metadata
  available_scps = {
    deny_ec2_creation = {
      name        = "DenyEC2Creation"
      description = "Prevents creation of EC2 instances"
      policy = templatefile("${path.module}/policies/deny-ec2-creation.json", {
        admin_role_arns = local.admin_role_arns
      })
    }
    deny_default_vpc = {
      name        = "DenyDefaultVPC"
      description = "Prevents creation of default VPCs and subnets"
      policy      = file("${path.module}/policies/deny-default-vpc.json")
    }
    deny_internet_egress = {
      name        = "DenyInternetEgress"
      description = "Prevents creation of internet gateways and NAT gateways"
      policy = templatefile("${path.module}/policies/deny-internet-egress.json", {
        admin_role_arns = local.admin_role_arns
      })
    }
    deny_leave_organization = {
      name        = "DenyLeaveOrganization"
      description = "Prevents accounts from leaving the organization"
      policy      = file("${path.module}/policies/deny-leave-organization.json")
    }
    deny_unapproved_regions = {
      name        = "DenyUnapprovedRegions"
      description = "Restricts actions to approved AWS regions only"
      policy = templatefile("${path.module}/policies/deny-unapproved-regions.json", {
        allowed_regions = local.allowed_regions
      })
    }
  }

  # Merge available SCPs with any custom SCPs
  all_scps = merge(local.available_scps, var.custom_scps)

  # Filter to only enabled SCPs
  enabled_scps = {
    for key, scp in local.all_scps : key => scp
    if contains(var.enabled_scps, key)
  }
}

# Create SCP policies
resource "aws_organizations_policy" "this" {
  for_each = local.enabled_scps

  name        = each.value.name
  description = each.value.description
  type        = "SERVICE_CONTROL_POLICY"
  content     = each.value.policy

  tags = merge(var.tags, {
    Name = each.value.name
  })
}

# Attach SCPs to targets (OUs or accounts)
resource "aws_organizations_policy_attachment" "this" {
  for_each = {
    for attachment in local.scp_attachments : "${attachment.scp_key}-${attachment.target_id}" => attachment
  }

  policy_id = aws_organizations_policy.this[each.value.scp_key].id
  target_id = each.value.target_id
}

locals {
  # Build list of all SCP-to-target attachments
  scp_attachments = flatten([
    for scp_key in var.enabled_scps : [
      for target_id in var.target_ids : {
        scp_key   = scp_key
        target_id = target_id
      }
    ]
    if contains(keys(local.enabled_scps), scp_key)
  ])
}
