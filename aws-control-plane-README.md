# AWS Control Plane

## Overview

This project manages the foundational control plane for the AWS Landing Zone, built on top of **Account Factory for Terraform (AFT)**. It is responsible for the lifecycle of all AWS accounts across the organization — from OU structure and account vending through to post-provisioning customizations and global baseline configurations.

Changes in this project directly affect how new AWS accounts are created, structured, and configured at birth. It should be treated as critical infrastructure: all changes require peer review, and pipelines are the only permitted path to applying changes — no manual console or CLI modifications.

---

## Project Structure

This project is composed of the following repositories, each mapping to a distinct concern within the AFT framework:

| Repository | Purpose |
|---|---|
| `organisation-units` | Defines the AWS Organizations OU hierarchy and account placement |
| `aft-vpc` | Provisions the VPC infrastructure required by the AFT deployment pipeline |
| `aft-deployment` | Core AFT configuration — the root module that deploys and configures AFT itself |
| `account-requests` | Terraform definitions for every account vending request submitted to AFT |
| `account-customisations` | Post-provisioning customizations scoped to individual accounts |
| `account-provisioning-customisations` | Customizations applied during the provisioning phase, before account handoff |
| `global-customisations` | Baseline configurations applied to every account in the organization |

---

## How AFT Works in This Project

```
account-requests
      │
      ▼
AFT Pipeline (aft-deployment)
      │
      ├──▶ account-provisioning-customisations   (during provisioning)
      │
      ├──▶ account-customisations                (per-account, post-provisioning)
      │
      └──▶ global-customisations                 (applied to all accounts)
```

1. A new account request is raised by adding a Terraform resource to `account-requests`.
2. AFT detects the change and triggers the account vending pipeline defined in `aft-deployment`.
3. The account is created in the OU defined in `organisation-units`.
4. `account-provisioning-customisations` runs during provisioning to apply pre-handoff config.
5. `account-customisations` applies any account-specific post-provisioning configuration.
6. `global-customisations` applies organization-wide baselines to the new account.

---

## Repository Details

### `organisation-units`

Defines the AWS Organizations Organizational Unit (OU) structure. The OU hierarchy drives account placement and is the attachment point for Service Control Policies (managed in `aws-security`).

- Changes here affect account placement and SCP inheritance
- OU structure should reflect your workload taxonomy (e.g. `Workloads/Production`, `Workloads/NonProd`, `Infrastructure`, `Sandbox`)
- Coordinate with the `aws-security` project before restructuring OUs — SCP attachments may be affected

### `aft-vpc`

Provisions the VPC used by AFT's own deployment pipeline. This is infrastructure for AFT itself, not for workload accounts.

- Typically a standalone VPC in the AFT management account
- Includes subnets, security groups, and VPC endpoints required for AFT's CodePipeline execution
- Changes here can disrupt the AFT pipeline — treat with extra caution

### `aft-deployment`

The root AFT Terraform module. Configures AFT core settings including:

- AFT management account and target Control Tower environment
- Feature flags (e.g. CloudTrail data events, Enterprise Support enrollment, SSO)
- Backend configuration for AFT's state management
- VPC configuration referencing `aft-vpc`

This repository should change infrequently. Updates are typically driven by AFT module version upgrades.

### `account-requests`

Every AWS account managed through AFT is represented here as a Terraform `aft_account_request` resource. Raising a new account request means adding a new resource definition to this repository and raising a PR.

Each request specifies:
- Account name, email, and OU placement
- Custom fields (e.g. cost centre, team, environment type)
- Which account customizations to apply

### `account-customisations`

Post-provisioning Terraform and/or Python scripts scoped to individual accounts or account types. Customizations are organized by account name or tag and applied after the account has been handed off by AFT.

Common uses include:
- Account-specific IAM roles or trust policies
- Bespoke tagging or budget alerts
- Application-specific baseline resources

### `account-provisioning-customisations`

Terraform and scripts executed during the provisioning phase — after the account exists but before it is considered ready. Unlike `account-customisations`, these run synchronously as part of the vending pipeline.

Common uses include:
- Enrolling the account in third-party tools
- Setting account-level AWS Config recording options
- Applying initial resource tagging or account aliases

### `global-customisations`

Terraform and scripts applied to every account in the organization on an ongoing basis. This is the right place for universal baselines that should be consistent everywhere.

Common uses include:
- Default EBS encryption settings
- Account-level S3 public access blocks
- Baseline IAM roles (e.g. break-glass, read-only audit)
- Default VPC deletion (where applicable)

---

## Making an Account Request

To request a new AWS account:

1. Branch from `main` in `account-requests`
2. Add a new `module "account_name"` block following the existing pattern
3. Specify the correct OU, custom fields, and applicable customization flags
4. Raise a PR — include the requestor, business justification, and environment type in the description
5. On merge, AFT will automatically begin the provisioning pipeline

> Account provisioning typically takes 20–40 minutes end to end.

---

## Contributing

- All changes must be applied via pipeline — no manual `terraform apply` against AFT resources
- PRs to `aft-deployment` require platform team lead approval in addition to the standard two-reviewer requirement
- Changes to `global-customisations` affect every account — test in a sandbox OU first
- Document any new customization flags in the relevant repository `README.md`

---

## Dependencies

| Dependency | Project | Notes |
|---|---|---|
| Landing Zone Terraform Modules | `aws-landing-zone-modules` | Modules consumed by customisation scripts |
| Service Control Policies | `aws-security` / `aws-scps` | SCPs attach to OUs defined in `organisation-units` |
| Network Hub | `aws-core-infra` / `network-hub` | Accounts may attach to Transit Gateway post-provisioning |

---

## Support and Contact

| Topic | Contact |
|---|---|
| New account requests | `#platform-engineering` Slack |
| AFT pipeline failures | `#platform-alerts` Slack |
| OU structure changes | Platform team + Security team sign-off required |
| Emergency break-glass | Contact platform team lead directly |
