module "it_policy" {
  source = "./modules/network_firewall_policy"

  providers = {
    aws    = aws.primary
    aws.dr = aws.dr
  }

  name_prefix      = "it"
  internal_cidr    = var.it_internal_cidr
  dr_internal_cidr = var.it_dr_internal_cidr
  dr_enabled       = var.dr_enabled

  allowed_egress_domains = var.it_allowed_egress_domains

  enable_ad_rules = var.it_enable_ad_rules

  onprem_cidr              = var.it_onprem_cidr
  enable_onprem_inspection = var.it_enable_onprem_inspection
  enable_onprem_ad_rules   = var.it_enable_onprem_ad_rules

  azure_cidr              = var.it_azure_cidr
  enable_azure_inspection = var.it_enable_azure_inspection
  enable_azure_ad_rules   = var.it_enable_azure_ad_rules

  tags = local.it_tags_primary
}

module "ot_policy" {
  source = "./modules/network_firewall_policy"

  providers = {
    aws    = aws.primary
    aws.dr = aws.dr
  }

  name_prefix      = "ot"
  internal_cidr    = var.ot_internal_cidr
  dr_internal_cidr = var.ot_dr_internal_cidr
  dr_enabled       = var.dr_enabled

  # No allowed_egress_domains — OT has no internet egress.
  # Domain allowlist rule group will not be created.

  enable_ad_rules = var.ot_enable_ad_rules

  onprem_cidr              = var.ot_onprem_cidr
  enable_onprem_inspection = var.ot_enable_onprem_inspection
  enable_onprem_ad_rules   = var.ot_enable_onprem_ad_rules

  azure_cidr              = var.ot_azure_cidr
  enable_azure_inspection = var.ot_enable_azure_inspection
  enable_azure_ad_rules   = var.ot_enable_azure_ad_rules

  tags = local.ot_tags_primary
}
