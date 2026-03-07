# ---------------------------------------------------------------
# Stateless rule group
# Broad forward rules are active during the build phase.
# Port-specific hardened replacements are documented in the locals
# port reference and should replace these rules once traffic
# patterns are understood and validated via firewall logs.
# ---------------------------------------------------------------
resource "aws_networkfirewall_rule_group" "stateless_forward" {
  name     = "${var.name_prefix}-stateless-forward"
  type     = "STATELESS"
  capacity = 300

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {

        # ---- Internal egress ----------------------------------------
        stateless_rule {
          priority = 10
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              sources { address_definition = var.internal_cidr }
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
              sources { address_definition = var.internal_cidr }
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
              sources { address_definition = var.internal_cidr }
              destinations { address_definition = "0.0.0.0/0" }
              protocols = [1]
            }
          }
        }

        # ---- East-west ----------------------------------------------
        stateless_rule {
          priority = 30
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              sources { address_definition = var.internal_cidr }
              destinations { address_definition = var.internal_cidr }
              protocols = [6]
            }
          }
        }

        stateless_rule {
          priority = 40
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              sources { address_definition = var.internal_cidr }
              destinations { address_definition = var.internal_cidr }
              protocols = [17]
            }
          }
        }

        stateless_rule {
          priority = 45
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              sources { address_definition = var.internal_cidr }
              destinations { address_definition = var.internal_cidr }
              protocols = [1]
            }
          }
        }

        # ---- On-prem -> internal ------------------------------------
        dynamic "stateless_rule" {
          for_each = var.enable_onprem_inspection ? [1] : []
          content {
            priority = 60
            rule_definition {
              actions = ["aws:forward_to_sfe"]
              match_attributes {
                sources { address_definition = var.onprem_cidr }
                destinations { address_definition = var.internal_cidr }
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
                destinations { address_definition = var.internal_cidr }
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
                destinations { address_definition = var.internal_cidr }
                protocols = [1]
              }
            }
          }
        }

        # ---- Azure -> internal --------------------------------------
        # Azure is private connectivity to AWS workloads only.
        # No internet egress via this firewall.
        # No on-prem transit — that connectivity exists independently.
        dynamic "stateless_rule" {
          for_each = var.enable_azure_inspection ? [1] : []
          content {
            priority = 80
            rule_definition {
              actions = ["aws:forward_to_sfe"]
              match_attributes {
                sources { address_definition = var.azure_cidr }
                destinations { address_definition = var.internal_cidr }
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
                destinations { address_definition = var.internal_cidr }
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
                destinations { address_definition = var.internal_cidr }
                protocols = [1]
              }
            }
          }
        }

        # ---- Default drop -------------------------------------------
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
# Stateful — East-West
# Broad pass rules active during build phase.
# AD rules added as port-specific rules when enable_ad_rules = true.
# When hardening: enable AD rules, validate via logs, then remove
# the broad pass rules — do not run both simultaneously.
# ---------------------------------------------------------------
resource "aws_networkfirewall_rule_group" "east_west" {
  name     = "${var.name_prefix}-east-west"
  type     = "STATEFUL"
  capacity = 200

  rule_group {
    rules_source {
      rules_string = join("\n", compact(concat(
        [
          "pass tcp ${var.internal_cidr} any -> ${var.internal_cidr} any (msg:\"${var.name_prefix} east-west TCP\"; sid:1000001; rev:1;)",
          "pass udp ${var.internal_cidr} any -> ${var.internal_cidr} any (msg:\"${var.name_prefix} east-west UDP\"; sid:1000002; rev:1;)",
          "pass icmp ${var.internal_cidr} any -> ${var.internal_cidr} any (msg:\"${var.name_prefix} east-west ICMP\"; sid:1000003; rev:1;)",
        ],
        var.enable_ad_rules ? [
          for r in local.ad_rules_tcp :
          "pass tcp ${var.internal_cidr} any -> ${var.internal_cidr} ${r.port} (msg:\"EW AD ${r.msg}\"; sid:10010${r.sid}; rev:1;)"
        ] : [],
        var.enable_ad_rules ? [
          for r in local.ad_rules_udp :
          "pass udp ${var.internal_cidr} any -> ${var.internal_cidr} ${r.port} (msg:\"EW AD ${r.msg}\"; sid:10020${r.sid}; rev:1;)"
        ] : [],
      )))
    }
  }

  tags = var.tags
}

# ---------------------------------------------------------------
# Stateful — On-premises (conditional)
# Bidirectional rules (<>) cover DC replication and auth flows
# in both directions across distinct CIDRs.
# ---------------------------------------------------------------
resource "aws_networkfirewall_rule_group" "onprem_inspection" {
  count = var.enable_onprem_inspection ? 1 : 0

  name     = "${var.name_prefix}-onprem-inspection"
  type     = "STATEFUL"
  capacity = 200

  rule_group {
    rules_source {
      rules_string = join("\n", compact(concat(
        [
          "pass tcp ${var.internal_cidr} any <> ${var.onprem_cidr} any (msg:\"${var.name_prefix} on-prem TCP\"; sid:1000050; rev:1;)",
          "pass udp ${var.internal_cidr} any <> ${var.onprem_cidr} any (msg:\"${var.name_prefix} on-prem UDP\"; sid:1000051; rev:1;)",
          "pass icmp ${var.internal_cidr} any <> ${var.onprem_cidr} any (msg:\"${var.name_prefix} on-prem ICMP\"; sid:1000052; rev:1;)",
        ],
        var.enable_onprem_ad_rules ? [
          for r in local.ad_rules_tcp :
          "pass tcp ${var.internal_cidr} any <> ${var.onprem_cidr} ${r.port} (msg:\"OP AD ${r.msg}\"; sid:10030${r.sid}; rev:1;)"
        ] : [],
        var.enable_onprem_ad_rules ? [
          for r in local.ad_rules_udp :
          "pass udp ${var.internal_cidr} any <> ${var.onprem_cidr} ${r.port} (msg:\"OP AD ${r.msg}\"; sid:10040${r.sid}; rev:1;)"
        ] : [],
      )))
    }
  }

  tags = var.tags
}

# ---------------------------------------------------------------
# Stateful — Azure (conditional)
# Scoped to AWS <-> Azure private connectivity only.
# Azure does not egress internet via this firewall.
# Azure <-> on-prem connectivity is handled independently.
# ---------------------------------------------------------------
resource "aws_networkfirewall_rule_group" "azure_inspection" {
  count = var.enable_azure_inspection ? 1 : 0

  name     = "${var.name_prefix}-azure-inspection"
  type     = "STATEFUL"
  capacity = 200

  rule_group {
    rules_source {
      rules_string = join("\n", compact(concat(
        [
          "pass tcp ${var.internal_cidr} any <> ${var.azure_cidr} any (msg:\"${var.name_prefix} Azure TCP\"; sid:1000060; rev:1;)",
          "pass udp ${var.internal_cidr} any <> ${var.azure_cidr} any (msg:\"${var.name_prefix} Azure UDP\"; sid:1000061; rev:1;)",
          "pass icmp ${var.internal_cidr} any <> ${var.azure_cidr} any (msg:\"${var.name_prefix} Azure ICMP\"; sid:1000062; rev:1;)",
        ],
        var.enable_azure_ad_rules ? [
          for r in local.ad_rules_tcp :
          "pass tcp ${var.internal_cidr} any <> ${var.azure_cidr} ${r.port} (msg:\"AZ AD ${r.msg}\"; sid:10050${r.sid}; rev:1;)"
        ] : [],
        var.enable_azure_ad_rules ? [
          for r in local.ad_rules_udp :
          "pass udp ${var.internal_cidr} any <> ${var.azure_cidr} ${r.port} (msg:\"AZ AD ${r.msg}\"; sid:10060${r.sid}; rev:1;)"
        ] : [],
      )))
    }
  }

  tags = var.tags
}

# ---------------------------------------------------------------
# Stateful — Domain allowlist
# HOME_NET is scoped to internal_cidr by default. On-prem is added
# when Pattern B egress is enabled. Azure is never included.
# ---------------------------------------------------------------
resource "aws_networkfirewall_rule_group" "domain_allowlist" {
  count = length(var.allowed_egress_domains) > 0 ? 1 : 0

  name     = "${var.name_prefix}-egress-domain-allowlist"
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
# Firewall policy
# ---------------------------------------------------------------
resource "aws_networkfirewall_firewall_policy" "main" {
  name = "${var.name_prefix}-firewall-policy"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateless_rule_group_reference {
      priority     = 1
      resource_arn = aws_networkfirewall_rule_group.stateless_forward.arn
    }

    stateful_engine_options {
      rule_order = "STRICT_ORDER"
    }

    stateful_rule_group_reference {
      priority     = 100
      resource_arn = aws_networkfirewall_rule_group.east_west.arn
    }

    dynamic "stateful_rule_group_reference" {
      for_each = var.enable_onprem_inspection ? [1] : []
      content {
        priority     = 200
        resource_arn = aws_networkfirewall_rule_group.onprem_inspection[0].arn
      }
    }

    dynamic "stateful_rule_group_reference" {
      for_each = var.enable_azure_inspection ? [1] : []
      content {
        priority     = 300
        resource_arn = aws_networkfirewall_rule_group.azure_inspection[0].arn
      }
    }

    dynamic "stateful_rule_group_reference" {
      for_each = length(var.allowed_egress_domains) > 0 ? [1] : []
      content {
        priority     = 400
        resource_arn = aws_networkfirewall_rule_group.domain_allowlist[0].arn
      }
    }

    stateful_default_actions = ["aws:drop_strict"]
  }

  tags = var.tags
}
