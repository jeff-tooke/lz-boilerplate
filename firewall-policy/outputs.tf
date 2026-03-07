output "it_policy_arn_primary" {
  description = "ARN of the IT primary firewall policy"
  value       = module.it_policy.policy_arn
}

output "it_policy_id_primary" {
  description = "ID of the IT primary firewall policy"
  value       = module.it_policy.policy_id
}

output "it_stateless_rule_group_arn_primary" {
  description = "ARN of the IT primary stateless rule group"
  value       = module.it_policy.stateless_rule_group_arn
}

output "it_east_west_rule_group_arn_primary" {
  description = "ARN of the IT primary east-west stateful rule group"
  value       = module.it_policy.east_west_rule_group_arn
}

output "it_onprem_rule_group_arn_primary" {
  description = "ARN of the IT primary on-prem stateful rule group. Null if not enabled."
  value       = module.it_policy.onprem_rule_group_arn
}

output "it_azure_rule_group_arn_primary" {
  description = "ARN of the IT primary Azure stateful rule group. Null if not enabled."
  value       = module.it_policy.azure_rule_group_arn
}

output "it_domain_allowlist_rule_group_arn_primary" {
  description = "ARN of the IT primary domain allowlist rule group. Null if no domains configured."
  value       = module.it_policy.domain_allowlist_rule_group_arn
}

output "it_policy_arn_dr" {
  description = "ARN of the IT DR firewall policy. Null if dr_enabled = false."
  value       = module.it_policy.dr_policy_arn
}

output "it_policy_id_dr" {
  description = "ID of the IT DR firewall policy. Null if dr_enabled = false."
  value       = module.it_policy.dr_policy_id
}

output "it_stateless_rule_group_arn_dr" {
  description = "ARN of the IT DR stateless rule group. Null if dr_enabled = false."
  value       = module.it_policy.dr_stateless_rule_group_arn
}

output "it_east_west_rule_group_arn_dr" {
  description = "ARN of the IT DR east-west stateful rule group. Null if dr_enabled = false."
  value       = module.it_policy.dr_east_west_rule_group_arn
}

output "it_onprem_rule_group_arn_dr" {
  description = "ARN of the IT DR on-prem stateful rule group. Null if not enabled."
  value       = module.it_policy.dr_onprem_rule_group_arn
}

output "it_azure_rule_group_arn_dr" {
  description = "ARN of the IT DR Azure stateful rule group. Null if not enabled."
  value       = module.it_policy.dr_azure_rule_group_arn
}

output "it_domain_allowlist_rule_group_arn_dr" {
  description = "ARN of the IT DR domain allowlist rule group. Null if not enabled or no domains configured."
  value       = module.it_policy.dr_domain_allowlist_rule_group_arn
}

output "ot_policy_arn_primary" {
  description = "ARN of the OT primary firewall policy"
  value       = module.ot_policy.policy_arn
}

output "ot_policy_id_primary" {
  description = "ID of the OT primary firewall policy"
  value       = module.ot_policy.policy_id
}

output "ot_stateless_rule_group_arn_primary" {
  description = "ARN of the OT primary stateless rule group"
  value       = module.ot_policy.stateless_rule_group_arn
}

output "ot_east_west_rule_group_arn_primary" {
  description = "ARN of the OT primary east-west stateful rule group"
  value       = module.ot_policy.east_west_rule_group_arn
}

output "ot_onprem_rule_group_arn_primary" {
  description = "ARN of the OT primary on-prem stateful rule group. Null if not enabled."
  value       = module.ot_policy.onprem_rule_group_arn
}

output "ot_azure_rule_group_arn_primary" {
  description = "ARN of the OT primary Azure stateful rule group. Null if not enabled."
  value       = module.ot_policy.azure_rule_group_arn
}

output "ot_domain_allowlist_rule_group_arn_primary" {
  description = "ARN of the OT primary domain allowlist rule group. Null — OT has no internet egress."
  value       = module.ot_policy.domain_allowlist_rule_group_arn
}

output "ot_policy_arn_dr" {
  description = "ARN of the OT DR firewall policy. Null if dr_enabled = false."
  value       = module.ot_policy.dr_policy_arn
}

output "ot_policy_id_dr" {
  description = "ID of the OT DR firewall policy. Null if dr_enabled = false."
  value       = module.ot_policy.dr_policy_id
}

output "ot_stateless_rule_group_arn_dr" {
  description = "ARN of the OT DR stateless rule group. Null if dr_enabled = false."
  value       = module.ot_policy.dr_stateless_rule_group_arn
}

output "ot_east_west_rule_group_arn_dr" {
  description = "ARN of the OT DR east-west stateful rule group. Null if dr_enabled = false."
  value       = module.ot_policy.dr_east_west_rule_group_arn
}

output "ot_onprem_rule_group_arn_dr" {
  description = "ARN of the OT DR on-prem stateful rule group. Null if not enabled."
  value       = module.ot_policy.dr_onprem_rule_group_arn
}

output "ot_azure_rule_group_arn_dr" {
  description = "ARN of the OT DR Azure stateful rule group. Null if not enabled."
  value       = module.ot_policy.dr_azure_rule_group_arn
}

output "ot_domain_allowlist_rule_group_arn_dr" {
  description = "ARN of the OT DR domain allowlist rule group. Null — OT has no internet egress."
  value       = module.ot_policy.dr_domain_allowlist_rule_group_arn
}
