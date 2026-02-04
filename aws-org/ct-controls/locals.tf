
# 1. OU ARNs (from Organizations or outputs of Account Factory)
locals {
  ou_arns = {
    "ou-security"  = "arn:aws:organizations::123456789012:ou/o-abcd/ou-aaaa"
    "ou-workloads" = "arn:aws:organizations::123456789012:ou/o-abcd/ou-bbbb"
    "ou-sandbox"   = "arn:aws:organizations::123456789012:ou/o-abcd/ou-cccc"
    "ou-platform"  = "arn:aws:organizations::123456789012:ou/o-abcd/ou-dddd"
  }
}

# 2. Define baseline and OU-specific controls
locals {
  baseline_controls = [
    "arn:aws:controltower:us-east-1::control/AWS-GR_ENCRYPTED_VOLUMES",
    "arn:aws:controltower:us-east-1::control/AWS-GR_LOGGING_ENABLED",
    "arn:aws:controltower:us-east-1::control/AWS-GR_MULTIFACTOR_REQUIRED",
    # … ~35 total baseline controls
  ]

  security_ou_controls = [
    "arn:aws:controltower:us-east-1::control/AWS-GR_RESTRICT_ROOT_USER"
    # additional security OU controls
  ]

  sandbox_ou_controls = [
    "arn:aws:controltower:us-east-1::control/AWS-GR_DISALLOW_INTERNET_GATEWAY"
  ]

  # 3. List of all OUs
  ous = keys(local.ou_arns)

  # 4. Compose controls per OU
  ou_controls = {
    for ou in local.ous :
    ou => distinct(concat(
      local.baseline_controls,
      lookup({
        "ou-security" = local.security_ou_controls
        "ou-sandbox"  = local.sandbox_ou_controls
      }, ou, [])
    ))
  }

  # 5. Flatten for for_each
  control_bindings = flatten([
    for ou, controls in local.ou_controls : [
      for control in controls : {
        ou      = ou
        control = control
      }
    ]
  ])
}
