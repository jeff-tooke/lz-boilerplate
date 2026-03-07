# ---------------------------------------------------------------
# DR — mirrors all primary resources into the DR region when
# dr_enabled = true. Uses the aws.dr provider alias which is
# configured at the root module level.
#
# All rule content, capacities, and toggle flags are identical
# to the primary deployment. The only differences are:
#   - name_prefix gets a -dr suffix
#   - resources are created in the DR region via the provider alias
#
# Provider alias must be passed at the module call site:
#   providers = {
#     aws.dr = aws.dr
#   }
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# DR Stateless rule group
# ---------------------------------------------------------------
resource "aws_networkfirewall_rule_group" "stateless_forward_dr" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr

  name     = "${var.name_prefix}-dr-stateless-forward"
  type     = "STATELESS"
  capacity = 300

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {

        stateless_rule {
          priority = 10
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              sources { address_definition = var.local.dr_home_net_cidrs }
              destinations { address_definition = "0.0.0.0/0" }
              protocols = [6]
            }
          }
        }

        stateless_rule {
          priority = 20
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              sources { address_definition = var.local.dr_home_net_cidrs }
              destinations { address_definition = "0.0.0.0/0" }
              protocols = [17]
            }
          }
        }

        stateless_rule {
          priority = 25
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              sources { address_definition = var.local.dr_home_net_cidrs }
              destinations { address_definition = "0.0.0.0/0" }
              protocols = [1]
            }
          }
        }

        stateless_rule {
          priority = 30
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              sources { address_definition = var.local.dr_home_net_cidrs }
              destinations { address_definition = var.local.dr_home_net_cidrs }
              protocols = [6]
            }
          }
        }

        stateless_rule {
          priority = 40
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              sources { address_definition = var.local.dr_home_net_cidrs }
              destinations { address_definition = var.local.dr_home_net_cidrs }
              protocols = [17]
            }
          }
        }

        stateless_rule {
          priority = 45
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              sources { address_definition = var.local.dr_home_net_cidrs }
              destinations { address_definition = var.local.dr_home_net_cidrs }
              protocols = [1]
            }
          }
        }

        dynamic "stateless_rule" {
          for_each = var.enable_onprem_inspection ? [1] : []
          content {
            priority = 60
            rule_definition {
              actions = ["aws:forward_to_sfe"]
              match_attributes {
                sources { address_definition = var.onprem_cidr }
                destinations { address_definition = var.local.dr_home_net_cidrs }
                protocols = [6]
              }
            }
          }
        }

        dynamic "stateless_rule" {
          for_each = var.enable_onprem_inspection ? [1] : []
          content {
            priority = 61
            rule_definition {
              actions = ["aws:forward_to_sfe"]
              match_attributes {
                sources { address_definition = var.onprem_cidr }
                destinations { address_definition = var.local.dr_home_net_cidrs }
                protocols = [17]
              }
            }
          }
        }

        dynamic "stateless_rule" {
          for_each = var.enable_onprem_inspection ? [1] : []
          content {
            priority = 62
            rule_definition {
              actions = ["aws:forward_to_sfe"]
              match_attributes {
                sources { address_definition = var.onprem_cidr }
                destinations { address_definition = var.local.dr_home_net_cidrs }
                protocols = [1]
              }
            }
          }
        }

        dynamic "stateless_rule" {
          for_each = var.enable_azure_inspection ? [1] : []
          content {
            priority = 80
            rule_definition {
              actions = ["aws:forward_to_sfe"]
              match_attributes {
                sources { address_definition = var.azure_cidr }
                destinations { address_definition = var.local.dr_home_net_cidrs }
                protocols = [6]
              }
            }
          }
        }

        dynamic "stateless_rule" {
          for_each = var.enable_azure_inspection ? [1] : []
          content {
            priority = 81
            rule_definition {
              actions = ["aws:forward_to_sfe"]
              match_attributes {
                sources { address_definition = var.azure_cidr }
                destinations { address_definition = var.local.dr_home_net_cidrs }
                protocols = [17]
              }
            }
          }
        }

        dynamic "stateless_rule" {
          for_each = var.enable_azure_inspection ? [1] : []
          content {
            priority = 82
            rule_definition {
              actions = ["aws:forward_to_sfe"]
              match_attributes {
                sources { address_definition = var.azure_cidr }
                destinations { address_definition = var.local.dr_home_net_cidrs }
                protocols = [1]
              }
            }
          }
        }

        stateless_rule {
          priority = 200
          rule_definition {
            actions = ["aws:drop"]
            match_attributes {}
          }
        }
      }
    }
  }

  tags = var.tags
}

# ---------------------------------------------------------------
# DR Stateful — East-West
# ---------------------------------------------------------------
resource "aws_networkfirewall_rule_group" "east_west_dr" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr

  name     = "${var.name_prefix}-dr-east-west"
  type     = "STATEFUL"
  capacity = 200

  rule_group {
    rules_source {
      rules_string = join("\n", compact(concat(
        [
          "pass tcp ${var.local.dr_home_net_cidrs} any -> ${var.local.dr_home_net_cidrs} any (msg:\"${var.name_prefix}-dr east-west TCP\"; sid:1000001; rev:1;)",
          "pass udp ${var.local.dr_home_net_cidrs} any -> ${var.local.dr_home_net_cidrs} any (msg:\"${var.name_prefix}-dr east-west UDP\"; sid:1000002; rev:1;)",
          "pass icmp ${var.local.dr_home_net_cidrs} any -> ${var.local.dr_home_net_cidrs} any (msg:\"${var.name_prefix}-dr east-west ICMP\"; sid:1000003; rev:1;)",
        ],
        var.enable_ad_rules ? [
          for r in local.ad_rules_tcp :
          "pass tcp ${var.local.dr_home_net_cidrs} any -> ${var.local.dr_home_net_cidrs} ${r.port} (msg:\"EW AD ${r.msg}\"; sid:10010${r.sid}; rev:1;)"
        ] : [],
        var.enable_ad_rules ? [
          for r in local.ad_rules_udp :
          "pass udp ${var.local.dr_home_net_cidrs} any -> ${var.local.dr_home_net_cidrs} ${r.port} (msg:\"EW AD ${r.msg}\"; sid:10020${r.sid}; rev:1;)"
        ] : [],
      )))
    }
  }

  tags = var.tags
}

# ---------------------------------------------------------------
# DR Stateful — On-premises (conditional)
# ---------------------------------------------------------------
resource "aws_networkfirewall_rule_group" "onprem_inspection_dr" {
  count    = var.dr_enabled && var.enable_onprem_inspection ? 1 : 0
  provider = aws.dr

  name     = "${var.name_prefix}-dr-onprem-inspection"
  type     = "STATEFUL"
  capacity = 200

  rule_group {
    rules_source {
      rules_string = join("\n", compact(concat(
        [
          "pass tcp ${var.local.dr_home_net_cidrs} any <> ${var.onprem_cidr} any (msg:\"${var.name_prefix}-dr on-prem TCP\"; sid:1000050; rev:1;)",
          "pass udp ${var.local.dr_home_net_cidrs} any <> ${var.onprem_cidr} any (msg:\"${var.name_prefix}-dr on-prem UDP\"; sid:1000051; rev:1;)",
          "pass icmp ${var.local.dr_home_net_cidrs} any <> ${var.onprem_cidr} any (msg:\"${var.name_prefix}-dr on-prem ICMP\"; sid:1000052; rev:1;)",
        ],
        var.enable_onprem_ad_rules ? [
          for r in local.ad_rules_tcp :
          "pass tcp ${var.local.dr_home_net_cidrs} any <> ${var.onprem_cidr} ${r.port} (msg:\"OP AD ${r.msg}\"; sid:10030${r.sid}; rev:1;)"
        ] : [],
        var.enable_onprem_ad_rules ? [
          for r in local.ad_rules_udp :
          "pass udp ${var.local.dr_home_net_cidrs} any <> ${var.onprem_cidr} ${r.port} (msg:\"OP AD ${r.msg}\"; sid:10040${r.sid}; rev:1;)"
        ] : [],
      )))
    }
  }

  tags = var.tags
}

# ---------------------------------------------------------------
# DR Stateful — Azure (conditional)
# ---------------------------------------------------------------
resource "aws_networkfirewall_rule_group" "azure_inspection_dr" {
  count    = var.dr_enabled && var.enable_azure_inspection ? 1 : 0
  provider = aws.dr

  name     = "${var.name_prefix}-dr-azure-inspection"
  type     = "STATEFUL"
  capacity = 200

  rule_group {
    rules_source {
      rules_string = join("\n", compact(concat(
        [
          "pass tcp ${var.local.dr_home_net_cidrs} any <> ${var.azure_cidr} any (msg:\"${var.name_prefix}-dr Azure TCP\"; sid:1000060; rev:1;)",
          "pass udp ${var.local.dr_home_net_cidrs} any <> ${var.azure_cidr} any (msg:\"${var.name_prefix}-dr Azure UDP\"; sid:1000061; rev:1;)",
          "pass icmp ${var.local.dr_home_net_cidrs} any <> ${var.azure_cidr} any (msg:\"${var.name_prefix}-dr Azure ICMP\"; sid:1000062; rev:1;)",
        ],
        var.enable_azure_ad_rules ? [
          for r in local.ad_rules_tcp :
          "pass tcp ${var.local.dr_home_net_cidrs} any <> ${var.azure_cidr} ${r.port} (msg:\"AZ AD ${r.msg}\"; sid:10050${r.sid}; rev:1;)"
        ] : [],
        var.enable_azure_ad_rules ? [
          for r in local.ad_rules_udp :
          "pass udp ${var.local.dr_home_net_cidrs} any <> ${var.azure_cidr} ${r.port} (msg:\"AZ AD ${r.msg}\"; sid:10060${r.sid}; rev:1;)"
        ] : [],
      )))
    }
  }

  tags = var.tags
}

# ---------------------------------------------------------------
# DR Stateful — Domain allowlist (conditional)
# ---------------------------------------------------------------
resource "aws_networkfirewall_rule_group" "domain_allowlist_dr" {
  count    = var.dr_enabled && length(var.allowed_egress_domains) > 0 ? 1 : 0
  provider = aws.dr

  name     = "${var.name_prefix}-dr-egress-domain-allowlist"
  type     = "STATEFUL"
  capacity = 100

  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["TLS_SNI", "HTTP_HOST"]
        targets              = var.allowed_egress_domains
      }
    }

    rule_variables {
      ip_sets {
        key = "HOME_NET"
        ip_set {
          definition = local.home_net_cidrs
        }
      }
    }
  }

  tags = var.tags
}

# ---------------------------------------------------------------
# DR Firewall policy
# ---------------------------------------------------------------
resource "aws_networkfirewall_firewall_policy" "dr" {
  count    = var.dr_enabled ? 1 : 0
  provider = aws.dr

  name = "${var.name_prefix}-dr-firewall-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateless_rule_group_reference {
      priority     = 1
      resource_arn = aws_networkfirewall_rule_group.stateless_forward_dr[0].arn
    }

    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }

    stateful_rule_group_reference {
      priority     = 100
      resource_arn = aws_networkfirewall_rule_group.east_west_dr[0].arn
    }

    dynamic "stateful_rule_group_reference" {
      for_each = var.enable_onprem_inspection ? [1] : []
      content {
        priority     = 200
        resource_arn = aws_networkfirewall_rule_group.onprem_inspection_dr[0].arn
      }
    }

    dynamic "stateful_rule_group_reference" {
      for_each = var.enable_azure_inspection ? [1] : []
      content {
        priority     = 300
        resource_arn = aws_networkfirewall_rule_group.azure_inspection_dr[0].arn
      }
    }

    dynamic "stateful_rule_group_reference" {
      for_each = length(var.allowed_egress_domains) > 0 ? [1] : []
      content {
        priority     = 400
        resource_arn = aws_networkfirewall_rule_group.domain_allowlist_dr[0].arn
      }
    }

    stateful_default_actions = ["aws:drop_strict"]
  }

  tags = var.tags
}
