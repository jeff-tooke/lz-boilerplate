# Firewall Policy

Terraform configuration for the AWS Network Firewall policy used across the Landing Zone hub network. Defines the stateless and stateful rule groups that govern egress, east-west (VPC-to-VPC), and (optionally) on-premises and Azure traffic.

## Architecture

Traffic passing through the AWS Network Firewall is evaluated in two stages:

```
Inbound packet
      │
      ▼
┌─────────────────────────────┐
│   Stateless Rule Group      │  Fast path — protocol/CIDR matching only.
│   stateless-forward-to-sfe  │  Matched traffic → stateful engine.
│                             │  Unmatched traffic → drop (priority 200).
└────────────┬────────────────┘
             │ aws:forward_to_sfe
             ▼
┌─────────────────────────────┐
│   Stateful Engine           │  STRICT_ORDER — first match wins.
│                             │
│   Priority 100              │
│   east-west-inspection      │  Pass internal VPC-to-VPC traffic.
│                             │
│   Priority 400              │
│   egress-domain-allowlist   │  Allow egress only to approved domains.
│                             │
│   Default: aws:drop_strict  │  Anything not matched is dropped.
└─────────────────────────────┘
```

## Build-Phase vs Hardened Rules

The active rules use broad port-open statements to allow the environment to bootstrap without friction. Commented-out hardened replacements are included inline throughout `main.tf` for every rule — swap them in once traffic patterns are understood and validated via firewall logs.

**Workflow:**
1. Deploy with broad rules active.
2. Enable firewall alert and flow logs (via the `network-firewall` module).
3. Review logs to confirm expected traffic patterns.
4. Uncomment the hardened per-port rules and remove the broad rules.
5. Re-apply and validate.

## Allowed Egress Domains

Outbound HTTPS/HTTP is restricted to the following domains (defined in `locals.tf`):

| Domain | Purpose |
|---|---|
| `.github.com` | Source control, Actions runners |
| `.dev.azure.com` | Azure DevOps pipelines |
| `.amazonaws.com` | AWS service APIs |

Add additional domains to `local.allowed_domains` in `locals.tf` as needed.

## Connecting to a Firewall

Pass `firewall_policy_arn` from this configuration's outputs into the `network-firewall` module:

```hcl
module "network_firewall" {
  source = "../terraform-modules/network-firewall"

  name                = "prod-hub"
  environment         = "production"
  vpc_id              = module.hub_vpc.vpc_id
  subnet_ids          = module.hub_vpc.firewall_subnet_ids_list
  firewall_policy_arn = data.terraform_remote_state.firewall_policy.outputs.firewall_policy_arn
}
```

## Extending for On-Premises / Azure

Stub rule groups and stateless rules for on-premises and Azure connectivity are included but commented out in `main.tf`. To enable:

1. Uncomment `onprem_cidr` / `azure_cidr` in `locals.tf` and set the correct CIDRs.
2. Uncomment the relevant stateless rules (priorities 60–91).
3. Uncomment `aws_networkfirewall_rule_group.onprem_inspection` and/or `azure_inspection`.
4. Uncomment the corresponding `stateful_rule_group_reference` blocks in the policy.

## Outputs

| Name | Description |
|---|---|
| `firewall_policy_arn` | ARN of the firewall policy — pass to the `network-firewall` module |
| `firewall_policy_name` | Name of the firewall policy |
| `stateless_rule_group_arn` | ARN of the stateless forward rule group |
| `domain_allowlist_rule_group_arn` | ARN of the egress domain allowlist rule group |
| `east_west_rule_group_arn` | ARN of the east-west inspection rule group |

## Requirements

| Name | Version |
|---|---|
| Terraform | >= 1.5.0, < 2.0.0 |
| AWS Provider | >= 5.0, < 6.0 |
