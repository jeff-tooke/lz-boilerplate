locals {
  # Common tags applied to all resources
  common_tags = merge(
    var.tags,
    {
      Environment   = var.environment
      ManagedBy     = "terraform"
      Module        = "network-firewall"
      ModuleVersion = local.module_version
    }
  )

  # Determine if we need to create a firewall policy
  create_policy = var.firewall_policy_arn == ""

  # Effective policy ARN: allow-all takes precedence, then created policy, then supplied ARN
  effective_firewall_policy_arn    = var.create_allow_all_policy ? aws_networkfirewall_firewall_policy.allow_all[0].arn : (local.create_policy ? aws_networkfirewall_firewall_policy.this[0].arn : var.firewall_policy_arn)
  effective_dr_firewall_policy_arn = var.create_allow_all_policy ? aws_networkfirewall_firewall_policy.allow_all_dr[0].arn : (local.create_policy ? aws_networkfirewall_firewall_policy.dr[0].arn : var.firewall_policy_arn)

  # Determine if we need to create log groups
  create_alert_log_group = var.logging_enabled && var.alert_log_destination_type == "CloudWatchLogs" && var.alert_log_destination == ""
  create_flow_log_group  = var.logging_enabled && var.flow_log_destination_type == "CloudWatchLogs" && var.flow_log_destination == ""

  # Log group names
  alert_log_group_name = "/aws/network-firewall/${var.name}/alert"
  flow_log_group_name  = "/aws/network-firewall/${var.name}/flow"

  # DR log group names
  dr_alert_log_group_name = "/aws/network-firewall/${var.name}-dr/alert"
  dr_flow_log_group_name  = "/aws/network-firewall/${var.name}-dr/flow"

  # Resolve actual log destinations
  alert_log_destination = var.alert_log_destination != "" ? var.alert_log_destination : (
    local.create_alert_log_group ? aws_cloudwatch_log_group.alert[0].name : ""
  )
  flow_log_destination = var.flow_log_destination != "" ? var.flow_log_destination : (
    local.create_flow_log_group ? aws_cloudwatch_log_group.flow[0].name : ""
  )

  # DR log destinations
  dr_alert_log_destination = var.dr_enabled && local.create_alert_log_group ? aws_cloudwatch_log_group.dr_alert[0].name : ""
  dr_flow_log_destination  = var.dr_enabled && local.create_flow_log_group ? aws_cloudwatch_log_group.dr_flow[0].name : ""

  # Build stateless rule group references for policy
  stateless_rule_group_refs = [
    for idx, rg in var.stateless_rule_groups : {
      resource_arn = aws_networkfirewall_rule_group.stateless[idx].arn
      priority     = rg.priority
    }
  ]

  # Build stateful rule group references for policy
  stateful_rule_group_refs = concat(
    [
      for idx, rg in var.stateful_rule_groups : {
        resource_arn = aws_networkfirewall_rule_group.stateful[idx].arn
        priority     = rg.priority
      }
    ],
    [
      for idx, rg in var.stateful_domain_rule_groups : {
        resource_arn = aws_networkfirewall_rule_group.stateful_domain[idx].arn
        priority     = rg.priority
      }
    ]
  )
}
