locals {
  # ── Account metadata ───────────────────────────────────────────────────────
  account_id           = data.aws_caller_identity.current.account_id
  account_name         = data.aws_ssm_parameter.account_name.value
  environment          = data.aws_ssm_parameter.environment.value
  system_domain        = data.aws_ssm_parameter.system_domain.value
  business_unit        = data.aws_ssm_parameter.business_unit.value
  business_criticality = data.aws_ssm_parameter.business_criticality.value

  # Federation role ARNs stored as a comma-separated String in SSM.
  # split() produces the list required for Principal.AWS in the trust policy.
  federation_role_arns = split(",", data.aws_ssm_parameter.federation_role_arns.value)

  # ── Region abbreviation ────────────────────────────────────────────────────
  region_abbreviations = {
    "eu-west-1" = "euw1"
    "eu-west-2" = "euw2"
    # "us-east-1" = "use1"
    # "us-west-2" = "usw2"
  }
  short_region = local.region_abbreviations[data.aws_region.current.name]

  # ── Domain-driven resource prefix ─────────────────────────────────────────
  # it  → "st-" prefix (IT/shared-services accounts)
  # ot  → "ot-" prefix (OT accounts — strictly isolated from IT)
  domain_prefix = local.system_domain == "ot" ? "ot" : "st"

  svc_name = data.aws_ssm_parameter.svc_name.value

  # ── Naming convention: <domain_prefix>-<svc-name>-<env>-<region-abbrev>-<resource-type>
  # Examples:
  #   it-payments  → st-payments-prod-euw2-tfstate
  #   ot-scada     → ot-scada-prod-euw2-tfstate
  # IAM (global) resources omit the region segment.
  name_prefix    = "${local.domain_prefix}-${local.svc_name}-${local.environment}-${local.short_region}"
  exec_role_name = "${local.domain_prefix}-${local.svc_name}-${local.environment}-tf-exec-role"

  # ── Individual resource names ──────────────────────────────────────────────
  kms_key_alias        = "${local.name_prefix}-kms"
  backup_kms_key_alias = "${local.name_prefix}-backup-kms"
  state_bucket_name    = "${local.name_prefix}-tfstate-${random_string.bucket_suffix.result}"
  state_logs_name      = "${local.name_prefix}-tfstate-logs-${random_string.bucket_suffix.result}"
  dynamodb_name        = "${local.name_prefix}-tflocks"
  backup_vault_name    = "${local.name_prefix}-backup-vault"

  # ── Backup vault lock decisions ────────────────────────────────────────────
  # t1/t2 → compliance lock (immutable after 3-day cooling-off period)
  # t3    → governance lock (removable by privileged users)
  backup_compliance_lock = contains(["t1", "t2"], local.business_criticality)
  backup_governance_lock = local.business_criticality == "t3"

  # ── Backup tier decisions ──────────────────────────────────────────────────
  # t1-t3 → geo-redundant DR vault in eu-west-1
  # t1-t2 → long-term vault with monthly 365-day retention
  backup_dr_enabled       = contains(["t1", "t2", "t3"], local.business_criticality)
  backup_longterm_enabled = contains(["t1", "t2"], local.business_criticality)

  # ── Backup schedule (tier-based) ───────────────────────────────────────────
  backup_schedule = (
    local.business_criticality == "t1" ? "cron(0 * * * ? *)" :   # hourly
    local.business_criticality == "t2" ? "cron(0 0/4 * * ? *)" : # every 4h
    "cron(0 3 * * ? *)"                                           # daily 03:00 UTC (t3/t4)
  )

  # ── DR / longterm resource names ───────────────────────────────────────────
  short_dr_region            = local.region_abbreviations[var.secondary_region]
  dr_backup_kms_alias        = "${local.domain_prefix}-${local.svc_name}-${local.environment}-${local.short_dr_region}-backup-kms"
  dr_backup_vault_name       = "${local.domain_prefix}-${local.svc_name}-${local.environment}-${local.short_dr_region}-backup-vault"
  backup_longterm_vault_name = "${local.domain_prefix}-${local.svc_name}-${local.environment}-${local.short_region}-backup-longterm-vault"
  backup_role_name           = "${local.domain_prefix}-${local.svc_name}-${local.environment}-backup-role"
  backup_plan_name           = "${local.domain_prefix}-${local.svc_name}-${local.environment}-backup-plan"
  backup_selection_name      = "${local.domain_prefix}-${local.svc_name}-${local.environment}-backup-selection"

  # ── Common tags ────────────────────────────────────────────────────────────
  common_tags = merge(
    var.tags,
    {
      Environment   = local.environment
      SystemDomain  = local.system_domain
      BusinessUnit  = local.business_unit
      ManagedBy     = "account-factory-terraform"
      Module        = "aft-global-customizations"
      ModuleVersion = local.module_version
    }
  )
}
