locals {
  common_tags = merge(
    var.tags,
    {
      Environment   = var.environment
      ManagedBy     = "terraform"
      Module        = "spoke-vpc"
      ModuleVersion = local.module_version
    }
  )

  ################################################################################
  # AZ Selection
  ################################################################################

  selected_azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(
    sort(data.aws_availability_zones.available.names),
    0,
    var.number_of_azs
  )
  num_azs = length(local.selected_azs)

  ################################################################################
  # Subnet Tier Names
  ################################################################################

  default_subnet_names   = ["private", "data", "spare", "reserved"]
  effective_subnet_names = length(var.subnet_names) > 0 ? var.subnet_names : slice(local.default_subnet_names, 0, var.number_of_subnets)

  ################################################################################
  # CIDR Auto-Slicing
  # total_subnets = num_azs × number_of_subnets
  # subnet_newbits = ceil(log2(max(total_subnets, 2)))  (min 1)
  ################################################################################

  total_subnets  = local.num_azs * var.number_of_subnets
  subnet_newbits = max(1, ceil(log(max(local.total_subnets, 2), 2)))

  ################################################################################
  # Flat Subnet Map: "tier-az" => { cidr, az, tier_name, tier_index, az_index }
  # Layout: tier-first so same-tier subnets are address-contiguous
  #   index = tier_index × num_azs + az_index
  ################################################################################

  subnet_map = {
    for combo in flatten([
      for ti, tier_name in local.effective_subnet_names : [
        for ai, az in local.selected_azs : {
          key        = "${tier_name}-${az}"
          cidr       = cidrsubnet(var.vpc_cidr, local.subnet_newbits, ti * local.num_azs + ai)
          az         = az
          tier_name  = tier_name
          tier_index = ti
          az_index   = ai
        }
      ]
    ]) : combo.key => combo
  }

  ################################################################################
  # TGW Attachment: first tier subnets (one per AZ)
  ################################################################################

  tgw_attachment_subnet_ids = [
    for az in local.selected_azs :
    aws_subnet.this["${local.effective_subnet_names[0]}-${az}"].id
  ]

  ################################################################################
  # TGW Route Table Wiring
  ################################################################################

  create_tgw_attachment      = var.transit_gateway_id != ""
  environment_route_table_id = lookup(var.environment_route_table_ids, var.environment, "")
  enable_tgw_rt_wiring       = local.create_tgw_attachment && var.inspection_route_table_id != "" && local.environment_route_table_id != ""
  enable_shared_svc_prop     = local.enable_tgw_rt_wiring && var.shared_services_route_table_id != ""
}
