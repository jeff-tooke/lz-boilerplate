# ---------------------------------------------------------------
# Primary outputs
# ---------------------------------------------------------------
output "policy_arn" {
  description = "ARN of the primary firewall policy"
  value       = aws_networkfirewall_firewall_policy.main.arn
}

output "policy_id" {
  description = "ID of the primary firewall policy"
  value       = aws_networkfirewall_firewall_policy.main.id
}

output "stateless_rule_group_arn" {
  description = "ARN of the primary stateless rule group"
  value       = aws_networkfirewall_rule_group.stateless_forward.arn
}

output "east_west_rule_group_arn" {
  description = "ARN of the primary east-west stateful rule group"
  value       = aws_networkfirewall_rule_group.east_west.arn
}

output "onprem_rule_group_arn" {
  description = "ARN of the primary on-prem stateful rule group. Null if not enabled."
  value       = var.enable_onprem_inspection ? aws_networkfirewall_rule_group.onprem_inspection[0].arn : null
}

output "azure_rule_group_arn" {
  description = "ARN of the primary Azure stateful rule group. Null if not enabled."
  value       = var.enable_azure_inspection ? aws_networkfirewall_rule_group.azure_inspection[0].arn : null
}

output "domain_allowlist_rule_group_arn" {
  description = "ARN of the primary domain allowlist stateful rule group"
  value       = length(var.allowed_egress_domains) > 0 ? aws_networkfirewall_rule_group.domain_allowlist[0].arn : null
}

# ---------------------------------------------------------------
# DR outputs
# ---------------------------------------------------------------
output "dr_policy_arn" {
  description = "ARN of the DR firewall policy. Null if dr_enabled = false."
  value       = var.dr_enabled ? aws_networkfirewall_firewall_policy.dr[0].arn : null
}

output "dr_policy_id" {
  description = "ID of the DR firewall policy. Null if dr_enabled = false."
  value       = var.dr_enabled ? aws_networkfirewall_firewall_policy.dr[0].id : null
}

output "dr_stateless_rule_group_arn" {
  description = "ARN of the DR stateless rule group. Null if dr_enabled = false."
  value       = var.dr_enabled ? aws_networkfirewall_rule_group.stateless_forward_dr[0].arn : null
}

output "dr_east_west_rule_group_arn" {
  description = "ARN of the DR east-west stateful rule group. Null if dr_enabled = false."
  value       = var.dr_enabled ? aws_networkfirewall_rule_group.east_west_dr[0].arn : null
}

output "dr_onprem_rule_group_arn" {
  description = "ARN of the DR on-prem stateful rule group. Null if not enabled."
  value       = var.dr_enabled && var.enable_onprem_inspection ? aws_networkfirewall_rule_group.onprem_inspection_dr[0].arn : null
}

output "dr_azure_rule_group_arn" {
  description = "ARN of the DR Azure stateful rule group. Null if not enabled."
  value       = var.dr_enabled && var.enable_azure_inspection ? aws_networkfirewall_rule_group.azure_inspection_dr[0].arn : null
}

output "dr_domain_allowlist_rule_group_arn" {
  description = "ARN of the DR domain allowlist stateful rule group. Null if dr_enabled = false."
  value       = var.dr_enabled && length(var.allowed_egress_domains) > 0 ? aws_networkfirewall_rule_group.domain_allowlist_dr[0].arn : null
}
