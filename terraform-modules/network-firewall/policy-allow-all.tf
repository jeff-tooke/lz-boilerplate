################################################################################
# TEMPORARY Allow-All Firewall Policy
#
# PURPOSE: Bootstrap policy for use while building and validating the hub
# network. With no rules and STRICT_ORDER, ANF drops all traffic by default.
# This policy passes everything through so routing and connectivity can be
# confirmed before real rules are authored.
#
# USAGE: Set create_allow_all_policy = true in the module call.
# When set, this policy takes precedence over the normal policy path
# (stateless_rule_groups / stateful_rule_groups inputs are ignored).
#
# WARNING: This policy performs NO inspection. Do NOT leave it enabled in
# production. Replace with a restrictive policy before go-live.
################################################################################

################################################################################
# Allow-All Policy (Primary Region)
################################################################################

resource "aws_networkfirewall_firewall_policy" "allow_all" {
  count = var.create_allow_all_policy ? 1 : 0

  name        = "${var.name}-policy-allow-all"
  description = "TEMPORARY allow-all policy — replace before production"

  firewall_policy {
    # Forward all stateless traffic to the stateful engine
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    # Default action for all stateful traffic: pass without inspection
    stateful_default_actions = ["aws:pass"]

    # DEFAULT_ACTION_ORDER with CONTINUE means mid-stream packets that
    # cannot be matched to a flow are also allowed through
    stateful_engine_options {
      rule_order              = "DEFAULT_ACTION_ORDER"
      stream_exception_policy = "CONTINUE"
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name}-policy-allow-all"
      Region    = "primary"
      Temporary = "true"
    }
  )
}

################################################################################
# Allow-All Policy (DR Region)
################################################################################

resource "aws_networkfirewall_firewall_policy" "allow_all_dr" {
  count    = var.dr_enabled && var.create_allow_all_policy ? 1 : 0
  provider = aws.dr

  name        = "${var.name}-policy-allow-all-dr"
  description = "TEMPORARY allow-all policy — replace before production (DR)"

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_default_actions = ["aws:pass"]

    stateful_engine_options {
      rule_order              = "DEFAULT_ACTION_ORDER"
      stream_exception_policy = "CONTINUE"
    }
  }

  tags = merge(
    local.common_tags,
    {
      Name      = "${var.name}-policy-allow-all-dr"
      Region    = "dr"
      Temporary = "true"
    }
  )
}
