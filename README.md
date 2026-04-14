# AWS Landing Zone — Terraform Module Library

## Overview

This project serves as the **single source of truth** for shared Terraform modules used to build and maintain an AWS Landing Zone. It provides standardized, versioned, and reusable building blocks — covering core areas such as account structure, VPC networking, IAM, logging, and security baselines — enabling teams to deploy compliant and consistent AWS environments at scale.

All downstream infrastructure projects consuming these modules can rely on a stable, well-tested foundation that enforces organizational best practices without requiring each team to re-implement common patterns from scratch. Changes to the Landing Zone architecture flow through this repository and are propagated to consumers via module versioning.

---

## Repository Structure

```
.
├── modules/
│   ├── account/              # AWS account baseline configuration
│   ├── networking/           # VPC, subnets, route tables, transit gateway
│   ├── iam/                  # IAM roles, policies, permission boundaries
│   ├── security/             # GuardDuty, Security Hub, Config rules, SCPs
│   ├── logging/              # CloudTrail, S3 log buckets, CloudWatch log groups
│   ├── dns/                  # Route 53 hosted zones and resolver rules
│   └── tagging/              # Shared tagging standards and enforcement
├── examples/
│   ├── full-landing-zone/    # End-to-end example using all modules
│   └── single-account/      # Minimal single-account setup example
├── tests/                    # Terratest-based automated tests
├── docs/                     # Architecture decision records (ADRs) and diagrams
└── CHANGELOG.md
```

---

## Module Catalogue

| Module | Description | Status |
|---|---|---|
| `account` | Provisions baseline AWS account settings: alias, password policy, root MFA enforcement, alternate contacts | Stable |
| `networking` | Creates VPCs, public/private subnets, internet and NAT gateways, route tables, and optional Transit Gateway attachments | Stable |
| `iam` | Manages cross-account roles, permission boundaries, and identity federation via AWS SSO / IAM Identity Center | Stable |
| `security` | Enables and configures GuardDuty, Security Hub, AWS Config, and Service Control Policies (SCPs) | Stable |
| `logging` | Sets up centralized logging via CloudTrail, S3 log archive buckets with lifecycle policies, and CloudWatch log groups | Stable |
| `dns` | Manages Route 53 hosted zones, resolver rules, and DNS firewall rule groups | Beta |
| `tagging` | Provides shared tag locals and an `aws_resourcegroups_group` to enforce tagging standards across resources | Stable |

---

## Getting Started

### Prerequisites

- Terraform `>= 1.5.0`
- AWS CLI configured with appropriate credentials
- Access to the AWS Management (root) account or a delegated admin account

### Consuming a Module

Reference modules from this repository in your downstream projects using the Azure DevOps Git source:

```hcl
module "networking" {
  source = "git::https://dev.azure.com/<org>/<project>/_git/<repo>//modules/networking?ref=v2.3.0"

  vpc_cidr             = "10.100.0.0/16"
  availability_zones   = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  enable_nat_gateway   = true
  single_nat_gateway   = false

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

Always pin to a specific **tag** (e.g. `?ref=v2.3.0`) rather than a branch to ensure stability in downstream pipelines.

---

## Versioning

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** — breaking changes to module inputs or outputs that require updates in consuming projects
- **MINOR** — new features or modules added in a backward-compatible manner
- **PATCH** — bug fixes and minor improvements with no interface changes

All releases are tagged in Git and documented in [`CHANGELOG.md`](./CHANGELOG.md). Consumers should subscribe to release notifications to stay informed of updates.

---

## Contributing

We welcome contributions from all teams building on the Landing Zone. Please follow these steps:

1. **Branch** — create a feature branch from `main` following the naming convention `feat/<short-description>` or `fix/<short-description>`.
2. **Develop** — implement your changes and ensure all modules include updated variable descriptions, outputs, and a `README.md` within the module directory.
3. **Test** — run `terratest` for the affected modules. All tests must pass before a PR is raised.
4. **Pull Request** — open a PR against `main` with a clear description of the change, its motivation, and any downstream impact. Reference any relevant ADRs.
5. **Review** — PRs require at least two approvals from the platform team before merging.
6. **Release** — releases are created by the platform team after merging, following the versioning policy above.

### Code Standards

- All modules must define explicit `variable` and `output` blocks with descriptions.
- Use `validation` blocks for variables where reasonable constraints can be enforced.
- Resources must use the shared `tagging` module and pass a `tags` variable.
- No hardcoded account IDs, region names, or secrets — use variables or data sources.
- Run `terraform fmt` and `terraform validate` before committing.

---

## Security and Compliance

All modules in this repository are designed with the following organizational guardrails in mind:

- **Least-privilege IAM** — roles and policies follow least-privilege principles. Permission boundaries are applied to all IAM roles created by downstream projects.
- **Encryption at rest** — S3 buckets, EBS volumes, and RDS instances created by these modules are encrypted by default using AWS KMS.
- **Centralized logging** — CloudTrail is enabled organization-wide and logs are shipped to an immutable, centralized archive account.
- **Security Hub standards** — the `security` module enforces CIS AWS Foundations and AWS Foundational Security Best Practices standards across all member accounts.
- **Service Control Policies** — SCPs are applied at the OU level to prevent unsafe actions such as disabling CloudTrail, leaving regions, or creating IAM users with console access.

Any change that weakens a security control requires explicit justification and sign-off from the Security team.

---

## Support and Contact

| Topic | Contact |
|---|---|
| Module usage questions | `#platform-engineering` Slack channel |
| Bug reports | Open an issue in this Azure DevOps project |
| Security concerns | Contact the Security team directly — do not raise a public issue |
| Architecture decisions | Raise an RFC via the `docs/adr/` process |

---

## License

Internal use only. All content in this repository is the property of the organization and must not be shared externally without prior approval.
