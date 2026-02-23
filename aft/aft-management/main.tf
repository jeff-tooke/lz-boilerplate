################################################################################
# AFT Framework Deployment
# Deploys Control Tower Account Factory for Terraform using Azure DevOps as VCS.
# AFT >= 1.18.0 is required for native Azure DevOps support.
# Apply this once from the management account context.
################################################################################

module "aft" {
  source = "github.com/aws-ia/terraform-aws-control_tower_account_factory?ref=1.18.1"

  # ── Core account IDs ──────────────────────────────────────────────────────
  ct_management_account_id  = var.ct_management_account_id
  log_archive_account_id    = var.log_archive_account_id
  audit_account_id          = var.audit_account_id
  aft_management_account_id = var.aft_management_account_id

  # ── Regions ───────────────────────────────────────────────────────────────
  ct_home_region              = "eu-west-2"
  tf_backend_secondary_region = "eu-west-1"

  # ── VCS: Azure DevOps (native support, AFT >= 1.18.0) ────────────────────
  vcs_provider = "azuredevops"

  account_request_repo_url            = var.account_request_repo_name
  account_request_repo_git_ref        = var.default_repo_branch
  global_customizations_repo_url      = var.global_customizations_repo_name
  global_customizations_repo_git_ref  = var.default_repo_branch
  account_customizations_repo_url     = var.account_customizations_repo_name
  account_customizations_repo_git_ref = var.default_repo_branch

  # ── Feature flags ─────────────────────────────────────────────────────────
  aft_feature_delete_default_vpcs_enabled = true
  aft_feature_cloudtrail_data_events      = var.aft_feature_cloudtrail_data_events
  aft_feature_enterprise_support          = var.aft_feature_enterprise_support
}
