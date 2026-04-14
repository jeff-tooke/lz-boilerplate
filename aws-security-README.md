# AWS Security

## Overview

This project manages the organization-wide security posture of the AWS Landing Zone. It covers identity and access management via AWS IAM Identity Center (SSO), preventive controls via Service Control Policies (SCPs), detective and responsive controls via AWS Config and Security Hub, and the shared Terraform module used to standardize permission set definitions across the organization.

Security controls defined here apply at the organization or OU level and affect all accounts. Every change must be reviewed by the Security team and, where it affects access or preventive controls, requires explicit sign-off before merging.

---

## Project Structure

| Repository | Purpose |
|---|---|
| `aws-access` | IAM Identity Center configuration — users, groups, account assignments, and permission set instantiation |
| `aws-controls` | Detective and responsive security controls — AWS Config rules, Security Hub standards, and Config remediations |
| `aws-scps` | Service Control Policies — preventive guardrails applied at the OU and account level |
| `aws-security-ssopermissionset-module` | Shared Terraform module for defining reusable, standardized SSO permission sets |

---

## Repository Details

### `aws-access`

Manages access to AWS accounts across the organization via AWS IAM Identity Center (formerly AWS SSO). This is the definitive source of truth for who can access which accounts with what level of permission.

**Key responsibilities:**

- **Account assignments** — maps groups (or users) to permission sets for specific accounts or OUs
- **Permission set instantiation** — calls the `aws-security-ssopermissionset-module` to define the permission sets available in the environment
- **Group management** — defines IAM Identity Center groups and their membership (or delegates membership to an identity provider such as Azure AD / Entra ID)

**Access model:**

The organization follows a least-privilege, role-based access model. Access tiers are:

| Permission Set | Intended Use | Session Duration |
|---|---|---|
| `AdministratorAccess` | Break-glass only — platform team leads | 1 hour |
| `PlatformEngineer` | Platform team — infrastructure management | 8 hours |
| `Developer` | Workload teams — deployment and debugging | 8 hours |
| `ReadOnly` | Audit, compliance, and support teams | 12 hours |
| `BillingReadOnly` | Finance and cost management | 12 hours |
| `SecurityAuditor` | Security team — investigation and compliance | 12 hours |

> AdministratorAccess is never assigned as a standing entitlement to any account. Access is granted on-demand via a separate privileged access workflow.

**Requesting access changes:**

Access changes (new assignments, permission set modifications, new group memberships) must be raised as a PR in this repository with the requestor's manager and the Security team as required reviewers. Access is not granted via tickets or verbal approval — the PR is the audit trail.

---

### `aws-controls`

Manages detective and responsive security controls applied across the organization.

**AWS Config:**
- Organization-level Config rules are defined here and applied to all member accounts
- Rules cover encryption compliance, public access settings, logging enablement, and security group hygiene
- Automatic remediation SSM documents are defined for select rules (e.g. auto-enabling S3 block public access)
- Conformance packs are used where a grouped set of rules maps to a compliance framework (e.g. CIS, NIST 800-53)

**Security Hub:**
- Organization-wide Security Hub is enabled and aggregated to the security tooling account
- Enabled standards: CIS AWS Foundations Benchmark, AWS Foundational Security Best Practices
- Finding suppression rules are managed here — all suppressions require documented justification
- Custom insights are defined for recurring investigation needs

**CloudTrail:**
- Organization-level CloudTrail is enabled and configured here
- Logs are delivered to an immutable S3 archive in the log archive account
- Log file integrity validation is enabled
- CloudWatch Logs integration is configured for real-time alerting on sensitive API calls

**Key alerting rules:**

| Alert | Trigger | Severity |
|---|---|---|
| Root account usage | Any `root` credential API call | Critical |
| Console login without MFA | `ConsoleLogin` with `MFAUsed: No` | High |
| SCP or Config rule modification | Changes to SCPs or Config rules | High |
| IAM policy with `*:*` attached | Config rule evaluation | Medium |
| Security Hub standard disabled | `UpdateStandardsControl` | High |

---

### `aws-scps`

Manages Service Control Policies applied across the AWS Organization. SCPs are preventive controls — they restrict what actions can be taken within an account, regardless of IAM permissions. A `Deny` in an SCP cannot be overridden by any IAM policy, including `AdministratorAccess`.

**SCP structure:**

```
aws-scps/
├── foundational/
│   ├── deny-root-actions.tf           # Prevents root account usage
│   ├── deny-region-restriction.tf     # Restricts to approved AWS regions only
│   ├── deny-leave-organization.tf     # Prevents accounts leaving the organization
│   └── deny-disable-cloudtrail.tf    # Prevents CloudTrail modification
├── data-protection/
│   ├── deny-s3-public-access.tf       # Blocks S3 bucket ACLs and public policies
│   └── deny-unencrypted-storage.tf   # Denies creation of unencrypted EBS/RDS
├── network/
│   ├── deny-tgw-detach.tf             # Prevents workloads detaching from Transit Gateway
│   └── deny-vpc-peering.tf           # Prevents direct VPC peering (enforce hub routing)
├── sandbox/
│   └── sandbox-restrictions.tf        # Additional restrictions for sandbox OU
└── attachments.tf                     # Defines which SCPs attach to which OUs
```

**SCP change policy:**

SCPs are among the highest-impact controls in the environment — an incorrectly written SCP can deny all actions in an entire OU, including to the platform team. All SCP changes must:

1. Be reviewed and approved by a Security team member **and** a platform team lead
2. Be tested against the [AWS IAM Policy Simulator](https://policysim.aws.amazon.com/) before merging
3. Be applied to the `Sandbox` OU first and validated before applying to production OUs
4. Include a rollback procedure in the PR description

> Never write an SCP that denies `organizations:*` or `sts:AssumeRole` without extremely careful scoping — these can lock out all access including the management account's ability to remove the SCP.

---

### `aws-security-ssopermissionset-module`

A shared Terraform module that standardizes how SSO permission sets are defined across the organization. Consumed by `aws-access` and any project that needs to define a permission set.

**What it provides:**

- A consistent interface for defining permission sets with AWS managed policies, customer managed policies, and inline policies
- Automatic enforcement of session duration limits
- Tagging of permission sets with owning team and purpose
- Optional managed policy attachment with guardrails to prevent overly broad policies (e.g. warns if `AdministratorAccess` is attached without a flag acknowledging the risk)

**Usage example:**

```hcl
module "developer_permission_set" {
  source = "git::https://dev.azure.com/<org>/aws-security/_git/aws-security-ssopermissionset-module?ref=v1.4.0"

  name             = "Developer"
  description      = "Developer access for workload account teams"
  session_duration = "PT8H"

  aws_managed_policies = [
    "arn:aws:iam::aws:policy/PowerUserAccess"
  ]

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyIAMWrite"
        Effect   = "Deny"
        Action   = ["iam:CreateUser", "iam:DeleteUser", "iam:AttachUserPolicy"]
        Resource = "*"
      }
    ]
  })

  tags = {
    Owner       = "platform-team"
    Environment = "all"
  }
}
```

**Module versioning** follows the same policy as `aws-landing-zone-modules` — always pin `aws-access` to a specific tag of this module.

---

## Governance and Change Control

| Change Type | Required Approvers | Notes |
|---|---|---|
| New access assignment | Manager + Security team | PR is the audit record |
| Permission set modification | Security team lead | Impact assess all current assignments |
| New SCP | Security team + Platform lead | Test in Sandbox OU first |
| SCP modification | Security team + Platform lead | Requires rollback plan in PR |
| Config rule suppression | Security team | Suppression must have documented justification and expiry |
| New Config rule | Security team | Validate rule logic in non-production accounts first |

---

## Dependencies

| Dependency | Project | Notes |
|---|---|---|
| OU structure | `aws-control-plane` / `organisation-units` | SCP attachments reference OU IDs defined there |
| Account IDs | `aws-control-plane` / `account-requests` | Access assignments reference account IDs |
| Permission set module | `aws-security-ssopermissionset-module` (this project) | Consumed by `aws-access` |

---

## Compliance and Audit

This project is subject to periodic internal and external audit. Key audit artefacts are:

- **Git history** — all access and control changes are traceable to a PR, approver, and timestamp
- **AWS Config** — continuous compliance evaluation across all accounts
- **Security Hub** — aggregated findings and compliance scores per account
- **CloudTrail** — immutable API-level audit log for all accounts

Do not delete branches, squash PR history, or force-push to `main` — the commit history is an audit artefact.

---

## Support and Contact

| Topic | Contact |
|---|---|
| Access requests | Raise a PR in `aws-access` |
| Security finding investigation | `#security-operations` Slack |
| SCP exception requests | Security team — documented business justification required |
| Urgent access issues | Page the on-call security engineer |
