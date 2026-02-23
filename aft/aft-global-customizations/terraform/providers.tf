################################################################################
# Providers
#
# AFT assumes the execution role before invoking Terraform — do NOT add
# assume_role blocks; the default provider already has target-account credentials.
#
# The dr alias is always declared (even for medium/low accounts) because
# Terraform requires provider blocks to exist regardless of whether resources
# using them are created. The aws.dr provider is only consumed by resources
# guarded by count = local.backup_dr_enabled ? 1 : 0.
################################################################################

provider "aws" {}

provider "aws" {
  alias  = "dr"
  region = var.secondary_region
}
