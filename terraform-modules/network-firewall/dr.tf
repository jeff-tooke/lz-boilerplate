################################################################################
# DR Region Provider
################################################################################

provider "aws" {
  alias  = "dr"
  region = var.secondary_region
}

################################################################################
# CloudWatch Log Groups for Firewall Logging (DR Region)
################################################################################

resource "aws_cloudwatch_log_group" "dr_alert" {
  count    = var.dr_enabled && local.create_alert_log_group ? 1 : 0
  provider = aws.dr

  name              = local.dr_alert_log_group_name
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.name}-firewall-alert-logs-dr"
      LogType = "alert"
      Region  = "dr"
    }
  )
}

resource "aws_cloudwatch_log_group" "dr_flow" {
  count    = var.dr_enabled && local.create_flow_log_group ? 1 : 0
  provider = aws.dr

  name              = local.dr_flow_log_group_name
  retention_in_days = var.log_retention_days

  tags = merge(
    local.common_tags,
    {
      Name    = "${var.name}-firewall-flow-logs-dr"
      LogType = "flow"
      Region  = "dr"
    }
  )
}

################################################################################
# Stateless Rule Groups (DR Region)
# Rule groups must be created in each region - they are not global
################################################################################

resource "aws_networkfirewall_rule_group" "dr_stateless" {
  count    = var.dr_enabled ? length(var.stateless_rule_groups) : 0
  provider = aws.dr

  name        = "${var.name}-${var.stateless_rule_groups[count.index].name}-dr"
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
      Name     = "${var.name}-${var.stateless_rule_groups[count.index].name}-dr"
      RuleType = "stateless"
      Region   = "dr"
    }
  )
}

################################################################################
# Stateful Rule Groups - Suricata Rules (DR Region)
################################################################################

resource "aws_networkfirewall_rule_group" "dr_stateful" {
  count    = var.dr_enabled ? length(var.stateful_rule_groups) : 0
  provider = aws.dr

  name        = "${var.name}-${var.stateful_rule_groups[count.index].name}-dr"
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
      Name     = "${var.name}-${var.stateful_rule_groups[count.index].name}-dr"
      RuleType = "stateful"
      Region   = "dr"
    }
  )
}

################################################################################
# Stateful Rule Groups - Domain Lists (DR Region)
################################################################################

resource "aws_networkfirewall_rule_group" "dr_stateful_domain" {
  count    = var.dr_enabled ? length(var.stateful_domain_rule_groups) : 0
  provider = aws.dr

  name        = "${var.name}-${var.stateful_domain_rule_groups[count.index].name}-dr"
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
      Name     = "${var.name}-${var.stateful_domain_rule_groups[count.index].name}-dr"
      RuleType = "stateful-domain"
      Region   = "dr"
    }
  )
}

################################################################################
# Firewall Policy (DR Region)
################################################################################

resource "aws_networkfirewall_firewall_policy" "dr" {
  count    = var.dr_enabled && local.create_policy ? 1 : 0
  provider = aws.dr

  name        = "${var.name}-policy-dr"
  description = "Firewall policy for ${var.name} (DR)"

  firewall_policy {
    stateless_default_actions          = var.policy_stateless_default_actions
    stateless_fragment_default_actions = var.policy_stateless_fragment_default_actions

    # Stateless rule group references (DR)
    dynamic "stateless_rule_group_reference" {
      for_each = var.stateless_rule_groups
      content {
        resource_arn = aws_networkfirewall_rule_group.dr_stateless[stateless_rule_group_reference.key].arn
        priority     = stateless_rule_group_reference.value.priority
      }
    }

    # Stateful rule group references (DR)
    dynamic "stateful_rule_group_reference" {
      for_each = var.stateful_rule_groups
      content {
        resource_arn = aws_networkfirewall_rule_group.dr_stateful[stateful_rule_group_reference.key].arn
        priority     = stateful_rule_group_reference.value.priority
      }
    }

    # Stateful domain rule group references (DR)
    dynamic "stateful_rule_group_reference" {
      for_each = var.stateful_domain_rule_groups
      content {
        resource_arn = aws_networkfirewall_rule_group.dr_stateful_domain[stateful_rule_group_reference.key].arn
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
    for_each = var.dr_encryption_key_arn != "" ? [1] : []
    content {
      type   = "CUSTOMER_KMS"
      key_id = var.dr_encryption_key_arn
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-policy-dr"
      Region = "dr"
    }
  )
}

################################################################################
# Network Firewall (DR Region)
################################################################################

resource "aws_networkfirewall_firewall" "dr" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr

  name                              = "${var.name}-firewall-dr"
  description                       = "Network firewall for ${var.name} hub (DR)"
  vpc_id                            = var.dr_vpc_id
  firewall_policy_arn               = local.effective_dr_firewall_policy_arn
  delete_protection                 = var.delete_protection
  subnet_change_protection          = var.subnet_change_protection
  firewall_policy_change_protection = var.firewall_policy_change_protection

  dynamic "subnet_mapping" {
    for_each = toset(var.dr_subnet_ids)
    content {
      subnet_id = subnet_mapping.value
    }
  }

  dynamic "encryption_configuration" {
    for_each = var.dr_encryption_key_arn != "" ? [1] : []
    content {
      type   = "CUSTOMER_KMS"
      key_id = var.dr_encryption_key_arn
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name   = "${var.name}-firewall-dr"
      Region = "dr"
    }
  )
}

################################################################################
# Firewall Logging Configuration (DR Region)
################################################################################

resource "aws_networkfirewall_logging_configuration" "dr" {
  count    = var.dr_enabled && var.logging_enabled ? 1 : 0
  provider = aws.dr

  firewall_arn = aws_networkfirewall_firewall.dr[0].arn

  logging_configuration {
    # Alert logs
    log_destination_config {
      log_destination = {
        logGroup = local.dr_alert_log_destination
      }
      log_destination_type = var.alert_log_destination_type
      log_type             = "ALERT"
    }

    # Flow logs
    log_destination_config {
      log_destination = {
        logGroup = local.dr_flow_log_destination
      }
      log_destination_type = var.flow_log_destination_type
      log_type             = "FLOW"
    }
  }
}
