################################################################################
# AFT Account Request
# Wrapper around the AFT account-request module. Each call to this module
# creates one account request that AFT processes through Control Tower.
#
# Governance fields (environment, system_domain, business_criticality, svc_name)
# are stored as BOTH:
#   - account_tags   → applied to the AWS account in Organizations
#   - custom_fields  → written to SSM in the vended account (/aft/account-request/custom-fields/*)
#                      so that customisation Terraform can read them without
#                      requiring cross-account Organizations API calls.
################################################################################

locals {
  # Mirror the same it → st mapping used in customisation layers so the
  # Control Tower account display name is consistent with resource naming.
  domain_prefix = var.system_domain == "ot" ? "ot" : "st"
}

module "aft_account_request" {
  source  = "aws-ia/control_tower_account_factory/aws//modules/aft-account-request"
  version = "~> 1.18"

  control_tower_parameters = {
    AccountEmail              = var.account_email
    AccountName               = "${local.domain_prefix}-${var.svc_name}-${var.environment}"
    ManagedOrganizationalUnit = var.ou_name
    SSOUserEmail              = var.account_email
    SSOUserFirstName          = "Platform"
    SSOUserLastName           = "Admin"
  }

  account_description         = var.account_description
  account_customizations_name = var.account_customizations_name

  # Custom fields are written to SSM as /aft/account-request/custom-fields/{key}
  custom_fields = {
    environment          = var.environment
    business_criticality = var.business_criticality
    system_domain        = var.system_domain
    business_unit        = var.business_unit
    svc_name             = var.svc_name
    ou_name              = var.ou_name
  }

  account_tags = merge(
    var.tags,
    {
      Environment         = var.environment
      SystemDomain        = var.system_domain
      BusinessUnit        = var.business_unit
      BusinessCriticality = var.business_criticality
      ServiceName         = var.service_name != "" ? var.service_name : "${local.domain_prefix}-${var.svc_name}-${var.environment}"
      ManagedBy           = "control-tower"
    }
  )
}
