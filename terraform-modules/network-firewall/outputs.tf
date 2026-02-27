################################################################################
# Module Version
################################################################################

output "module_version" {
  description = "Version of the network-firewall module"
  value       = local.module_version
}

################################################################################
# Primary Region - Firewall Outputs
################################################################################

output "firewall_id" {
  description = "ID of the primary Network Firewall"
  value       = aws_networkfirewall_firewall.this.id
}

output "firewall_arn" {
  description = "ARN of the primary Network Firewall"
  value       = aws_networkfirewall_firewall.this.arn
}

output "firewall_name" {
  description = "Name of the primary Network Firewall"
  value       = aws_networkfirewall_firewall.this.name
}

output "firewall_status" {
  description = "Status of the primary Network Firewall"
  value       = aws_networkfirewall_firewall.this.firewall_status
}

# The key output - endpoint IDs by subnet/AZ for route table integration
output "firewall_endpoint_ids" {
  description = "Map of subnet ID to firewall endpoint ID. Use these for route table next-hop configuration."
  value = {
    for sync_state in aws_networkfirewall_firewall.this.firewall_status[0].sync_states :
    sync_state.availability_zone => sync_state.attachment[0].endpoint_id
  }
}

output "firewall_endpoint_ids_by_subnet" {
  description = "Map of subnet ID to firewall endpoint ID"
  value = {
    for sync_state in aws_networkfirewall_firewall.this.firewall_status[0].sync_states :
    sync_state.attachment[0].subnet_id => sync_state.attachment[0].endpoint_id
  }
}

################################################################################
# Primary Region - Policy Outputs
################################################################################

output "firewall_policy_arn" {
  description = "ARN of the active firewall policy"
  value       = local.effective_firewall_policy_arn
}

output "firewall_policy_id" {
  description = "ID of the active firewall policy (null if using external policy)"
  value       = var.create_allow_all_policy ? aws_networkfirewall_firewall_policy.allow_all[0].id : (local.create_policy ? aws_networkfirewall_firewall_policy.this[0].id : null)
}

################################################################################
# Primary Region - Rule Group Outputs
################################################################################

output "stateless_rule_group_arns" {
  description = "List of stateless rule group ARNs"
  value       = aws_networkfirewall_rule_group.stateless[*].arn
}

output "stateful_rule_group_arns" {
  description = "List of stateful rule group ARNs"
  value       = aws_networkfirewall_rule_group.stateful[*].arn
}

output "stateful_domain_rule_group_arns" {
  description = "List of stateful domain rule group ARNs"
  value       = aws_networkfirewall_rule_group.stateful_domain[*].arn
}

################################################################################
# Primary Region - Logging Outputs
################################################################################

output "alert_log_group_name" {
  description = "CloudWatch log group name for alert logs"
  value       = local.create_alert_log_group ? aws_cloudwatch_log_group.alert[0].name : var.alert_log_destination
}

output "alert_log_group_arn" {
  description = "CloudWatch log group ARN for alert logs (null if using external destination)"
  value       = local.create_alert_log_group ? aws_cloudwatch_log_group.alert[0].arn : null
}

output "flow_log_group_name" {
  description = "CloudWatch log group name for flow logs"
  value       = local.create_flow_log_group ? aws_cloudwatch_log_group.flow[0].name : var.flow_log_destination
}

output "flow_log_group_arn" {
  description = "CloudWatch log group ARN for flow logs (null if using external destination)"
  value       = local.create_flow_log_group ? aws_cloudwatch_log_group.flow[0].arn : null
}

################################################################################
# DR Region - Firewall Outputs
################################################################################

output "dr_firewall_id" {
  description = "ID of the DR Network Firewall (null if DR not enabled)"
  value       = var.dr_enabled ? aws_networkfirewall_firewall.dr[0].id : null
}

output "dr_firewall_arn" {
  description = "ARN of the DR Network Firewall (null if DR not enabled)"
  value       = var.dr_enabled ? aws_networkfirewall_firewall.dr[0].arn : null
}

output "dr_firewall_name" {
  description = "Name of the DR Network Firewall (null if DR not enabled)"
  value       = var.dr_enabled ? aws_networkfirewall_firewall.dr[0].name : null
}

output "dr_firewall_status" {
  description = "Status of the DR Network Firewall (null if DR not enabled)"
  value       = var.dr_enabled ? aws_networkfirewall_firewall.dr[0].firewall_status : null
}

# DR firewall endpoint IDs - critical for DR routing
output "dr_firewall_endpoint_ids" {
  description = "Map of AZ to DR firewall endpoint ID (empty if DR not enabled)"
  value = var.dr_enabled ? {
    for sync_state in aws_networkfirewall_firewall.dr[0].firewall_status[0].sync_states :
    sync_state.availability_zone => sync_state.attachment[0].endpoint_id
  } : {}
}

output "dr_firewall_endpoint_ids_by_subnet" {
  description = "Map of subnet ID to DR firewall endpoint ID (empty if DR not enabled)"
  value = var.dr_enabled ? {
    for sync_state in aws_networkfirewall_firewall.dr[0].firewall_status[0].sync_states :
    sync_state.attachment[0].subnet_id => sync_state.attachment[0].endpoint_id
  } : {}
}

################################################################################
# DR Region - Policy Outputs
################################################################################

output "dr_firewall_policy_arn" {
  description = "ARN of the active DR firewall policy (null if DR not enabled)"
  value       = var.dr_enabled ? local.effective_dr_firewall_policy_arn : null
}

output "dr_firewall_policy_id" {
  description = "ID of the active DR firewall policy (null if DR not enabled or using external policy)"
  value       = var.dr_enabled ? (var.create_allow_all_policy ? aws_networkfirewall_firewall_policy.allow_all_dr[0].id : (local.create_policy ? aws_networkfirewall_firewall_policy.dr[0].id : null)) : null
}

################################################################################
# DR Region - Rule Group Outputs
################################################################################

output "dr_stateless_rule_group_arns" {
  description = "List of DR stateless rule group ARNs (empty if DR not enabled)"
  value       = var.dr_enabled ? aws_networkfirewall_rule_group.dr_stateless[*].arn : []
}

output "dr_stateful_rule_group_arns" {
  description = "List of DR stateful rule group ARNs (empty if DR not enabled)"
  value       = var.dr_enabled ? aws_networkfirewall_rule_group.dr_stateful[*].arn : []
}

output "dr_stateful_domain_rule_group_arns" {
  description = "List of DR stateful domain rule group ARNs (empty if DR not enabled)"
  value       = var.dr_enabled ? aws_networkfirewall_rule_group.dr_stateful_domain[*].arn : []
}

################################################################################
# DR Region - Logging Outputs
################################################################################

output "dr_alert_log_group_name" {
  description = "CloudWatch log group name for DR alert logs (null if DR not enabled)"
  value       = var.dr_enabled && local.create_alert_log_group ? aws_cloudwatch_log_group.dr_alert[0].name : null
}

output "dr_alert_log_group_arn" {
  description = "CloudWatch log group ARN for DR alert logs (null if DR not enabled)"
  value       = var.dr_enabled && local.create_alert_log_group ? aws_cloudwatch_log_group.dr_alert[0].arn : null
}

output "dr_flow_log_group_name" {
  description = "CloudWatch log group name for DR flow logs (null if DR not enabled)"
  value       = var.dr_enabled && local.create_flow_log_group ? aws_cloudwatch_log_group.dr_flow[0].name : null
}

output "dr_flow_log_group_arn" {
  description = "CloudWatch log group ARN for DR flow logs (null if DR not enabled)"
  value       = var.dr_enabled && local.create_flow_log_group ? aws_cloudwatch_log_group.dr_flow[0].arn : null
}
