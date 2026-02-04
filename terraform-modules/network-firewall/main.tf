################################################################################
# CloudWatch Log Groups for Firewall Logging (Primary Region)
################################################################################

resource "aws_cloudwatch_log_group" "alert" {
  count = local.create_alert_log_group ? 1 : 0

  name              = local.alert_log_group_name
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.name}-firewall-alert-logs"
      LogType = "alert"
    }
  )
}

resource "aws_cloudwatch_log_group" "flow" {
  count = local.create_flow_log_group ? 1 : 0

  name              = local.flow_log_group_name
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.name}-firewall-flow-logs"
      LogType = "flow"
    }
  )
}

################################################################################
# Stateless Rule Groups (Primary Region)
################################################################################

resource "aws_networkfirewall_rule_group" "stateless" {
  count = length(var.stateless_rule_groups)

  name        = "${var.name}-${var.stateless_rule_groups[count.index].name}"
  description = var.stateless_rule_groups[count.index].description
  type        = "STATELESS"
  capacity    = var.stateless_rule_groups[count.index].capacity

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        dynamic "stateless_rule" {
          for_each = var.stateless_rule_groups[count.index].rules
          content {
            priority = stateless_rule.value.priority
            rule_definition {
              actions = stateless_rule.value.actions
              match_attributes {
                protocols = stateless_rule.value.match.protocols

                dynamic "source" {
                  for_each = stateless_rule.value.match.source_cidrs
                  content {
                    address_definition = source.value
                  }
                }

                dynamic "destination" {
                  for_each = stateless_rule.value.match.destination_cidrs
                  content {
                    address_definition = destination.value
                  }
                }

                dynamic "source_port" {
                  for_each = stateless_rule.value.match.source_ports
                  content {
                    from_port = source_port.value.from
                    to_port   = source_port.value.to
                  }
                }

                dynamic "destination_port" {
                  for_each = stateless_rule.value.match.destination_ports
                  content {
                    from_port = destination_port.value.from
                    to_port   = destination_port.value.to
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.name}-${var.stateless_rule_groups[count.index].name}"
      RuleType = "stateless"
    }
  )
}

################################################################################
# Stateful Rule Groups - Suricata Rules (Primary Region)
################################################################################

resource "aws_networkfirewall_rule_group" "stateful" {
  count = length(var.stateful_rule_groups)

  name        = "${var.name}-${var.stateful_rule_groups[count.index].name}"
  description = var.stateful_rule_groups[count.index].description
  type        = "STATEFUL"
  capacity    = var.stateful_rule_groups[count.index].capacity

  rule_group {
    rules_source {
      rules_string = var.stateful_rule_groups[count.index].rules
    }

    dynamic "stateful_rule_options" {
      for_each = var.policy_stateful_rule_order == "STRICT_ORDER" ? [1] : []
      content {
        rule_order = "STRICT_ORDER"
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.name}-${var.stateful_rule_groups[count.index].name}"
      RuleType = "stateful"
    }
  )
}

################################################################################
# Stateful Rule Groups - Domain Lists (Primary Region)
################################################################################

resource "aws_networkfirewall_rule_group" "stateful_domain" {
  count = length(var.stateful_domain_rule_groups)

  name        = "${var.name}-${var.stateful_domain_rule_groups[count.index].name}"
  description = var.stateful_domain_rule_groups[count.index].description
  type        = "STATEFUL"
  capacity    = var.stateful_domain_rule_groups[count.index].capacity

  rule_group {
    dynamic "rule_variables" {
      for_each = length(var.stateful_domain_rule_groups[count.index].home_net_cidrs) > 0 ? [1] : []
      content {
        ip_sets {
          key = "HOME_NET"
          ip_set {
            definition = var.stateful_domain_rule_groups[count.index].home_net_cidrs
          }
        }
      }
    }

    rules_source {
      rules_source_list {
        generated_rules_type = var.stateful_domain_rule_groups[count.index].action
        target_types         = var.stateful_domain_rule_groups[count.index].protocols
        targets              = var.stateful_domain_rule_groups[count.index].domain_list
      }
    }

    dynamic "stateful_rule_options" {
      for_each = var.policy_stateful_rule_order == "STRICT_ORDER" ? [1] : []
      content {
        rule_order = "STRICT_ORDER"
      }
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name     = "${var.name}-${var.stateful_domain_rule_groups[count.index].name}"
      RuleType = "stateful-domain"
    }
  )
}

################################################################################
# Firewall Policy (Primary Region)
################################################################################

resource "aws_networkfirewall_firewall_policy" "this" {
  count = local.create_policy ? 1 : 0

  name        = "${var.name}-policy"
  description = "Firewall policy for ${var.name}"

  firewall_policy {
    stateless_default_actions          = var.policy_stateless_default_actions
    stateless_fragment_default_actions = var.policy_stateless_fragment_default_actions

    # Stateless rule group references
    dynamic "stateless_rule_group_reference" {
      for_each = local.stateless_rule_group_refs
      content {
        resource_arn = stateless_rule_group_reference.value.resource_arn
        priority     = stateless_rule_group_reference.value.priority
      }
    }

    # Stateful rule group references
    dynamic "stateful_rule_group_reference" {
      for_each = local.stateful_rule_group_refs
      content {
        resource_arn = stateful_rule_group_reference.value.resource_arn
        priority     = stateful_rule_group_reference.value.priority
      }
    }

    # Stateful engine options for STRICT_ORDER
    dynamic "stateful_engine_options" {
      for_each = var.policy_stateful_rule_order == "STRICT_ORDER" ? [1] : []
      content {
        rule_order              = "STRICT_ORDER"
        stream_exception_policy = "DROP"
      }
    }
  }

  dynamic "encryption_configuration" {
    for_each = var.encryption_key_arn != "" ? [1] : []
    content {
      type   = "CUSTOMER_KMS"
      key_id = var.encryption_key_arn
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${var.name}-policy"
    }
  )
}

################################################################################
# Network Firewall (Primary Region)
################################################################################

resource "aws_networkfirewall_firewall" "this" {
  name                              = "${var.name}-firewall"
  description                       = "Network firewall for ${var.name} hub"
  vpc_id                            = var.vpc_id
  firewall_policy_arn               = local.create_policy ? aws_networkfirewall_firewall_policy.this[0].arn : var.firewall_policy_arn
  delete_protection                 = var.delete_protection
  subnet_change_protection          = var.subnet_change_protection
  firewall_policy_change_protection = var.firewall_policy_change_protection

  dynamic "subnet_mapping" {
    for_each = toset(var.subnet_ids)
    content {
      subnet_id = subnet_mapping.value
    }
  }

  dynamic "encryption_configuration" {
    for_each = var.encryption_key_arn != "" ? [1] : []
    content {
      type   = "CUSTOMER_KMS"
      key_id = var.encryption_key_arn
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-firewall"
      Region = "primary"
    }
  )
}

################################################################################
# Firewall Logging Configuration (Primary Region)
################################################################################

resource "aws_networkfirewall_logging_configuration" "this" {
  count = var.logging_enabled ? 1 : 0

  firewall_arn = aws_networkfirewall_firewall.this.arn

  logging_configuration {
    # Alert logs
    log_destination_config {
      log_destination = {
        logGroup = local.alert_log_destination
      }
      log_destination_type = var.alert_log_destination_type
      log_type             = "ALERT"
    }

    # Flow logs
    log_destination_config {
      log_destination = {
        logGroup = local.flow_log_destination
      }
      log_destination_type = var.flow_log_destination_type
      log_type             = "FLOW"
    }
  }
}
