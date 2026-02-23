################################################################################
# Current Account / Region
################################################################################

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

################################################################################
# AFT-Injected SSM Parameters
# AFT pre-populates these in every vended account before running customisations.
################################################################################

data "aws_ssm_parameter" "account_id" {
  name = "/aft/account/account-id"
}

data "aws_ssm_parameter" "account_name" {
  name = "/aft/account/account-name"
}

################################################################################
# Custom Fields (from account request — written to SSM by AFT)
################################################################################

data "aws_ssm_parameter" "environment" {
  name = "/aft/account-request/custom-fields/environment"
}

data "aws_ssm_parameter" "system_domain" {
  name = "/aft/account-request/custom-fields/system_domain"
}

data "aws_ssm_parameter" "business_unit" {
  name = "/aft/account-request/custom-fields/business_unit"
}

data "aws_ssm_parameter" "business_criticality" {
  name = "/aft/account-request/custom-fields/business_criticality"
}

data "aws_ssm_parameter" "svc_name" {
  name = "/aft/account-request/custom-fields/svc_name"
}

################################################################################
# Federation Role ARNs
# Copied into the vended account by the pre_api_helper.py pre-hook.
# See api_helpers/python/pre_api_helper.py for details.
################################################################################

data "aws_ssm_parameter" "federation_role_arns" {
  name = "/aft/config/federation-role-arns"
}
