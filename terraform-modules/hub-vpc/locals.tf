locals {
  common_tags = merge(
    var.tags,
    {
      Environment   = var.environment
      ManagedBy     = "terraform"
      Module        = "hub-vpc"
      ModuleVersion = local.module_version
    }
  )

  # Primary region subnet mappings
  firewall_subnets = {
    for idx, az in var.availability_zones : az => {
      cidr = var.firewall_subnet_cidrs[idx]
      az   = az
      name = "${var.name}-firewall-${az}"
    }
  }

  tgw_attachment_subnets = {
    for idx, az in var.availability_zones : az => {
      cidr = var.tgw_attachment_subnet_cidrs[idx]
      az   = az
      name = "${var.name}-tgw-attachment-${az}"
    }
  }

  egress_subnets = {
    for idx, az in var.availability_zones : az => {
      cidr = var.egress_subnet_cidrs[idx]
      az   = az
      name = "${var.name}-egress-${az}"
    }
  }

  endpoint_subnets = {
    for idx, az in var.availability_zones : az => {
      cidr = var.endpoint_subnet_cidrs[idx]
      az   = az
      name = "${var.name}-endpoints-${az}"
    }
  }

  # DR region subnet mappings (only when DR is enabled)
  # All DR resource names have '-dr' appended for clear identification
  dr_firewall_subnets = var.dr_enabled ? {
    for idx, az in var.dr_availability_zones : az => {
      cidr = var.dr_firewall_subnet_cidrs[idx]
      az   = az
      name = "${var.name}-firewall-${az}-dr"
    }
  } : {}

  dr_tgw_attachment_subnets = var.dr_enabled ? {
    for idx, az in var.dr_availability_zones : az => {
      cidr = var.dr_tgw_attachment_subnet_cidrs[idx]
      az   = az
      name = "${var.name}-tgw-attachment-${az}-dr"
    }
  } : {}

  dr_egress_subnets = var.dr_enabled ? {
    for idx, az in var.dr_availability_zones : az => {
      cidr = var.dr_egress_subnet_cidrs[idx]
      az   = az
      name = "${var.name}-egress-${az}-dr"
    }
  } : {}

  dr_endpoint_subnets = var.dr_enabled ? {
    for idx, az in var.dr_availability_zones : az => {
      cidr = var.dr_endpoint_subnet_cidrs[idx]
      az   = az
      name = "${var.name}-endpoints-${az}-dr"
    }
  } : {}
}
