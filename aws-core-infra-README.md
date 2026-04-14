# AWS Core Infrastructure

## Overview

This project manages the shared networking backbone of the AWS Landing Zone. It provides the centralized network infrastructure that all workload accounts connect to, including hub-and-spoke routing via AWS Transit Gateway, centralized internet egress and ingress, and network-layer security enforcement via AWS Network Firewall.

Infrastructure in this project is foundational — it underpins connectivity for every workload account in the organization. Changes should be planned carefully, communicated to affected teams, and applied during a scheduled maintenance window where possible.

---

## Project Structure

| Repository | Purpose |
|---|---|
| `network-hub` | Centralized network hub: Transit Gateway, shared VPCs, routing, and connectivity |
| `firewall-policy` | AWS Network Firewall policy definitions — stateless and stateful rules |

---

## Architecture Overview

This project implements a **hub-and-spoke** network topology:

```
                    ┌─────────────────────────────┐
                    │        Network Hub Account   │
                    │                             │
                    │   ┌─────────────────────┐   │
  Internet ◀───────────▶│  Inspection VPC     │   │
                    │   │  (Network Firewall) │   │
                    │   └──────────┬──────────┘   │
                    │              │               │
                    │   ┌──────────▼──────────┐   │
                    │   │  Transit Gateway    │   │
                    │   └──┬──────┬──────┬───┘   │
                    └──────┼──────┼──────┼────────┘
                           │      │      │
               ┌───────────┘      │      └───────────┐
               ▼                  ▼                   ▼
        Workload Account   Workload Account    Workload Account
        (Production)       (Non-Production)    (Shared Services)
```

All inter-account and internet-bound traffic is routed through the Inspection VPC where AWS Network Firewall enforces policy before traffic is permitted to flow.

---

## Repository Details

### `network-hub`

Manages all infrastructure within the centralized network hub account. This is the core of the organization's network plane.

**Key resources:**

- **Transit Gateway (TGW)** — the central routing fabric. All spoke VPCs (in workload accounts) attach to the TGW. Route tables segment traffic by environment type (production, non-production, shared services) to enforce isolation.
- **Inspection VPC** — a dedicated VPC through which all traffic is routed for firewall inspection. Houses the AWS Network Firewall endpoints and manages the routing between the TGW and the internet gateway.
- **Egress VPC** — centralized internet egress point. NAT Gateways are managed here rather than in individual workload accounts, reducing cost and centralizing outbound traffic visibility.
- **TGW Route Tables** — separate route tables enforce traffic segmentation:
  - Production spokes cannot route directly to non-production spokes (all cross-environment traffic is inspected)
  - Shared services are accessible from all environments
  - All internet-bound traffic is routed through the Inspection VPC
- **RAM Shares** — the TGW and any shared subnets are shared to workload accounts via AWS Resource Access Manager (RAM)

**Inputs consumed from other projects:**
- Account IDs for TGW attachment acceptance (sourced from `aws-control-plane`)
- CIDR ranges defined per account/OU (agreed at account vending time)

### `firewall-policy`

Manages AWS Network Firewall rule groups and firewall policies. Decoupled from `network-hub` so that security rules can be updated independently of core network infrastructure.

**Structure:**

```
firewall-policy/
├── stateless/
│   ├── allow-established.tf     # Allow return traffic for established connections
│   └── default-deny.tf          # Default stateless drop rule (lowest priority)
├── stateful/
│   ├── domain-allowlist.tf      # Suricata rules: permitted egress FQDNs
│   ├── threat-intel.tf          # AWS managed threat intelligence rule groups
│   └── custom-rules.tf          # Organization-specific stateful rules
└── policy.tf                    # Firewall policy assembling rule groups
```

**Rule group categories:**

| Group | Type | Purpose |
|---|---|---|
| `allow-established` | Stateless | Permits return traffic for established flows |
| `domain-allowlist` | Stateful (Suricata) | Explicit allowlist of permitted egress domains |
| `threat-intel` | Stateful (Managed) | AWS-managed feeds blocking known malicious IPs/domains |
| `custom-rules` | Stateful (Suricata) | Organization-specific rules — lateral movement prevention, protocol enforcement |
| `default-deny` | Stateless | Lowest-priority catch-all drop |

> Firewall policy changes take effect within minutes of a successful pipeline run. Overly restrictive rules can silently drop traffic for all workloads. Always validate rule changes in a non-production context first and review firewall metrics before and after applying.

---

## Connecting a New Account to the Network Hub

When a new workload account is provisioned via `aws-control-plane`, connecting it to the network hub involves:

1. **TGW Attachment** — the workload account creates a TGW attachment to the shared Transit Gateway (RAM-shared from `network-hub`). This is typically handled by the account's VPC module.
2. **Attachment Acceptance** — `network-hub` must accept the TGW attachment. This is automated via a pipeline step that polls for pending attachments and accepts those belonging to known account IDs.
3. **Route Table Association** — the attachment is associated with the correct TGW route table based on environment type (production, non-production, shared services).
4. **CIDR Registration** — the account's VPC CIDR is added to the relevant TGW route table propagations so other spokes can route to it.

The account VPC CIDR must be agreed before provisioning and must not overlap with any existing allocation. Maintain a CIDR allocation register outside of Terraform to prevent conflicts.

---

## Operational Considerations

### Making Firewall Rule Changes

1. Branch from `main` in `firewall-policy`
2. Add or modify rules under the appropriate category
3. Test Suricata rule syntax locally using `suricata -T`
4. Raise a PR — include the business justification, affected traffic flows, and rollback plan
5. After merge, monitor the `DroppedPackets` CloudWatch metric for 30 minutes post-deployment

### Making Network Hub Changes

Changes to TGW route tables, VPC routing, or firewall endpoint placement can cause network outages. Follow this process:

1. Raise a change request in your ITSM tool with impact assessment
2. Communicate to workload account owners via `#platform-announcements`
3. Apply during a scheduled maintenance window
4. Have a rollback plan ready — TGW route table changes can be reverted quickly, but VPC/subnet changes may require longer recovery

### Monitoring

| Metric | Alarm Threshold | Action |
|---|---|---|
| `DroppedPackets` (Firewall) | Sustained spike > baseline | Review recent firewall policy changes |
| TGW attachment state | Any attachment moves to `failed` | Investigate attachment and routing config |
| NAT Gateway error count | > 0 for 5 minutes | Check route table and NAT GW state |

---

## Dependencies

| Dependency | Project | Notes |
|---|---|---|
| Account IDs | `aws-control-plane` | Required for TGW attachment acceptance automation |
| DNS Resolver Rules | `aws-landing-zone-modules` / `dns` | Resolver rules propagated to spoke VPCs via RAM |
| SCPs | `aws-security` / `aws-scps` | SCPs prevent workload accounts from detaching from TGW |

---

## Contributing

- No manual `terraform apply` — all changes via pipeline only
- `firewall-policy` and `network-hub` pipelines are separate — coordinate if changes span both
- Destructive changes to TGW route tables or firewall endpoints require platform team lead approval
- Add a rollback procedure to the PR description for any routing or firewall change

---

## Support and Contact

| Topic | Contact |
|---|---|
| Firewall rule requests | Raise a PR in `firewall-policy` with justification |
| New account connectivity | `#platform-engineering` Slack |
| Network incidents | `#platform-alerts` Slack — page on-call if P1 |
| CIDR allocation | Platform team maintains the allocation register |
