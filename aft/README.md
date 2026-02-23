# AWS Account Vending

This repository contains the configuration and automation that creates new AWS accounts and applies a consistent security and infrastructure baseline to each one. The process is driven by AWS Control Tower and Account Factory for Terraform (AFT).

---

## How it works

When a new AWS account is needed, a developer adds a small Terraform file to this repository describing the account. Merging that file to `main` triggers an automated pipeline that:

1. Creates the AWS account inside the correct Organisational Unit (OU)
2. Applies a **global baseline** to every account (state storage, KMS keys, IAM roles)
3. Applies **account-level customisations** (backup schedules, IAM policies)

The result is a fully configured AWS account, ready for workload deployments, with no manual console steps required.

---

## Repository layout

```
aft-account-request/          Account request definitions — add new accounts here
  account-requests/           One .tf file per OU (e.g. it-prod.tf, sandbox.tf)
  modules/account-request/    Shared module used by all account requests

aft-global-customizations/    Baseline applied to every vended account
  terraform/                  S3 state bucket, DynamoDB lock table, KMS keys, IAM role
  api_helpers/python/         Pre-hook script that runs before Terraform

aft-account-customizations/
  Standard/                   Default customisation: backup vaults, IAM policy attachment

aft-management/               One-time AFT framework deployment (already applied)
```

---

## Requesting a new account

### 1. Choose the right OU

Accounts are grouped into Organisational Units that reflect their purpose and risk level:

| OU | Use for |
|----|---------|
| `it-prod` | IT production workloads |
| `it-nonprod` | IT dev / test / pre-prod workloads |
| `ot-prod` | OT (Operational Technology) production |
| `ot-nonprod` | OT non-production |
| `core` | Shared infrastructure services |
| `sandbox` | Experimentation — no production data |
| `control-plane` | Platform team accounts |

### 2. Add an account request

Open the relevant file in `aft-account-request/account-requests/` (e.g. `it-nonprod.tf`) and add a module block:

```hcl
module "my_service_nonprod" {
  source = "../modules/account-request"

  account_email    = "aws-my-service-nonprod@example.com"
  account_description = "My Service — non-production"
  svc_name         = "my-service"
  environment      = "dev"
  system_domain    = "it"
  business_unit    = "my-team"
  business_criticality = "t3"
  ou_name          = "Root/infrastructure/it-nonprod"

  account_customizations_name = "Standard"

  tags = {}
}
```

Key fields:

| Field | What to put here |
|-------|-----------------|
| `account_email` | A unique email address for the account root user |
| `svc_name` | Short identifier for your service (no spaces) |
| `environment` | `dev`, `test`, `pre-prod`, `prod`, or `sandbox` |
| `system_domain` | `it` for most workloads; `ot` for operational technology |
| `business_criticality` | See the tier table below |
| `ou_name` | Full OU path — must match the file you are editing |

### 3. Raise a pull request

Open a PR against `main`. The account will be vended automatically once the PR is approved and merged.

---

## Business criticality tiers

The `business_criticality` field controls the backup and disaster recovery strategy applied to the account. Choose the tier that matches your recovery requirements.

| Tier | Recovery approach | Backup frequency | Cross-region DR |
|------|-----------------|-----------------|----------------|
| `t0` | Rebuild from IaC — no backup needed | None | No |
| `t1` | Hourly backups, full geo-redundancy | Hourly | Yes |
| `t2` | Regular backups with long-term retention | Every 4 hours | Yes |
| `t3` | Daily backups | Daily | Yes |
| `t4` | Daily backups, no DR | Daily | No |

When in doubt, use `t3`. Use `t1` or `t2` only for workloads where data loss or downtime would have a direct business impact. Use `t0` only for accounts whose contents can be fully recreated from code.

---

## What gets created in every account

Regardless of tier, every vended account receives:

- **S3 bucket** — stores Terraform state files, versioned and encrypted
- **DynamoDB table** — prevents concurrent Terraform runs from conflicting
- **KMS keys** — encrypts state files and backup data
- **Terraform Execution Role** — the IAM role that Azure DevOps pipelines assume to deploy infrastructure into the account
- **Backup vault** — receives backups for any resource tagged `backup = "true"`

---

## Access model

Azure DevOps pipelines access vended accounts by assuming the **Terraform Execution Role** via an IAM federation role. Each OU has its own dedicated federation role, so a pipeline authorised for non-production accounts cannot access production accounts.

You do not need to manage IAM users, access keys, or console passwords.

---

## Pre-requisites before vending into a new OU

If you are creating accounts in an OU that has never been used before, an SSM parameter must be created in the AFT management account before the first account is vended:

```
/aft/config/ou-federation-role/<ou-slug>
```

For example, for a new OU at `Root/infrastructure/it-nonprod` the slug is `it-nonprod` and the parameter value is the ARN of the Azure DevOps federation role for that OU. Reach out to the platform team to have this created.

---

## Troubleshooting

**The pipeline failed saying no federation role parameter exists for my OU slug**
The SSM pre-requisite above is missing. Ask the platform team to create the parameter.

**I need to change the backup tier for an existing account**
Update the `business_criticality` value in the account request file and merge to `main`. AFT will re-run customisations and update the backup configuration.

**I need a non-standard IAM policy on the execution role**
The `account_customizations_name` field selects which customisation template to apply. The default is `Standard` (AdministratorAccess). Speak to the platform team about alternative templates.
