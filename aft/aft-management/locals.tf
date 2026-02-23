locals {
  common_tags = merge(
    var.tags,
    {
      ManagedBy     = "terraform"
      Module        = "aft-management"
      ModuleVersion = local.module_version
    }
  )
}
