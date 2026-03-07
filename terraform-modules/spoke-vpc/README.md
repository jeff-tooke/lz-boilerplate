# spoke-vpc

**Module version:** 1.0.0
**Terraform:** >= 1.5.0 | **AWS Provider:** >= 5.0

---

## What does this module do?

This module creates a **spoke VPC** — a private network in an AWS account that connects back to a central hub network. Think of it like plugging a new office into a corporate WAN: the spoke VPC is the office, and the hub is the central data centre.

When you use this module, it will automatically:

- Create a VPC (your private network) with the IP address range you specify
- Divide that range into subnets spread across multiple Availability Zones (physical data centres within a region) for resilience
- Connect the VPC to the central Transit Gateway so it can communicate with other accounts and the internet via the hub
- Optionally configure performance and security features (see [Optional Features](#optional-features) below)

You do **not** need to manually calculate subnet IP ranges, wire up route tables, or configure Transit Gateway routing — the module handles all of that.

---

## Prerequisites

Before using this module, the following must already exist (typically created by the network/platform team):

- A **Transit Gateway** in the hub account, shared to this account via RAM
- Per-environment **Transit Gateway route tables** in the hub (one each for dev, test, preprod, prod)
- An **inspection route table** in the hub (for traffic to pass through the network firewall)
- Optionally: a **shared services route table** in the hub

The IDs for all of the above are outputs from the hub Terraform and should be passed in as inputs to this module.

---

## Basic Usage

```hcl
module "spoke_vpc" {
  source = "../terraform-modules/spoke-vpc"

  name        = "my-application"
  environment = "dev"
  vpc_cidr    = "10.1.0.0/16"

  # Connect to the Transit Gateway
  transit_gateway_id = "tgw-0abc123def456"

  # Route tables from the hub module outputs
  environment_route_table_ids = {
    dev     = "tgw-rtb-0dev000"
    test    = "tgw-rtb-0tst000"
    preprod = "tgw-rtb-0pre000"
    prod    = "tgw-rtb-0prd000"
  }
  inspection_route_table_id    = "tgw-rtb-0firewall"
  shared_services_route_table_id = "tgw-rtb-0shared"

  tags = {
    Team    = "my-team"
    Project = "my-application"
  }
}
```

This will create:
- A VPC with CIDR `10.1.0.0/16`
- 2 subnets (one per Availability Zone), automatically sized from the CIDR
- Route tables wired to the Transit Gateway
- All traffic flowing through the hub's network firewall for inspection

---

## Configuring Subnets

By default the module creates **one subnet tier** across **two Availability Zones**. You can expand this:

```hcl
# Three tiers (e.g. application, database, management) across three AZs
number_of_subnets = 3
number_of_azs     = 3
subnet_names      = ["application", "database", "management"]
```

The module automatically carves the `vpc_cidr` into equally-sized subnets — you don't need to work out the CIDR maths yourself.

Subnets of the same tier are address-contiguous across AZs, which makes firewall rules and security group policies easier to manage.

---

## Optional Features

All optional features are **off by default** and are enabled by setting a flag to `true`.

### S3 Gateway Endpoint

```hcl
enable_s3_endpoint = true
```

Creates a direct, private route from the VPC to Amazon S3. Without this, S3 traffic travels through the Transit Gateway and network firewall, incurring data transfer costs and adding latency. The gateway endpoint is free and keeps S3 traffic on AWS's internal network.

A policy is automatically applied to restrict access to S3 buckets **within your AWS Organisation only**, preventing data from being uploaded to external or personal AWS accounts.

> **Organisation ID:** The module will look this up automatically. If you prefer to supply it explicitly (e.g. to avoid requiring `organizations:DescribeOrganization` permission):
> ```hcl
> organization_id = "o-xxxxxxxxxx"
> ```

---

### DynamoDB Gateway Endpoint

```hcl
enable_dynamodb_endpoint = true
```

Same as the S3 gateway endpoint but for Amazon DynamoDB. Keeps DynamoDB traffic on AWS's internal network, reducing cost and latency. Also applies an organisation-restriction policy.

---

### Route53 Resolver Rule Associations

```hcl
enable_resolver_rule_associations = true
```

Your hub account likely has DNS forwarding rules — for example, rules that forward queries for on-premises domain names (like `internal.company.com`) to your on-premises DNS servers, or rules that resolve private AWS service endpoints via the hub.

Enabling this setting automatically discovers all such DNS rules that have been shared with your account via RAM and associates them with this VPC, so workloads in the spoke can resolve those names correctly.

**Gateway endpoint interaction:** If you have enabled the S3 or DynamoDB gateway endpoints, the module will automatically skip associating any DNS forwarding rules for those services. This is correct behaviour — gateway endpoints route traffic directly without DNS forwarding, so having a forwarding rule for S3 or DynamoDB alongside a gateway endpoint would be counterproductive.

---

## All Input Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `name` | Yes | — | A short name prefix applied to all resources (e.g. `my-app`) |
| `environment` | Yes | — | One of: `dev`, `test`, `preprod`, `prod` |
| `vpc_cidr` | Yes | — | The IP address range for the VPC (e.g. `10.1.0.0/16`). Must not overlap with other VPCs. |
| `number_of_azs` | No | `2` | How many Availability Zones to spread subnets across (1–6). Ignored if `availability_zones` is set. |
| `availability_zones` | No | `[]` | Explicit list of AZ names to use (e.g. `["eu-west-1a", "eu-west-1b"]`). Overrides `number_of_azs`. |
| `number_of_subnets` | No | `1` | How many subnet tiers to create per AZ (1–4). |
| `subnet_names` | No | `[]` | Names for each subnet tier (e.g. `["app", "db"]`). Defaults to `private`, `data`, `spare`, `reserved`. |
| `transit_gateway_id` | No | `""` | The ID of the Transit Gateway to attach to. Leave empty to skip TGW attachment entirely. |
| `environment_route_table_ids` | No | `{}` | Map of environment name to TGW route table ID (from hub outputs). The correct entry is auto-selected based on `environment`. |
| `inspection_route_table_id` | No | `""` | TGW route table ID for the network firewall. Required for full hub routing to work. |
| `shared_services_route_table_id` | No | `""` | TGW route table ID for shared services (e.g. DNS, NTP). |
| `enable_dns_hostnames` | No | `true` | Whether EC2 instances get DNS hostnames. Leave as default unless you have a specific reason to change it. |
| `enable_dns_support` | No | `true` | Whether DNS resolution is enabled in the VPC. Leave as default. |
| `enable_s3_endpoint` | No | `false` | Create a free S3 gateway endpoint to keep S3 traffic off the TGW. |
| `enable_dynamodb_endpoint` | No | `false` | Create a free DynamoDB gateway endpoint to keep DynamoDB traffic off the TGW. |
| `organization_id` | No | `""` | Your AWS Organisation ID (e.g. `o-xxxxxxxxxx`). Used in gateway endpoint policies. Auto-discovered if left empty. |
| `enable_resolver_rule_associations` | No | `false` | Discover and associate all RAM-shared DNS forwarding rules with this VPC. |
| `tags` | No | `{}` | Additional tags to apply to all resources (e.g. `{ Team = "platform" }`). |

---

## Outputs

These values are available after the module has been applied. Other Terraform modules or configurations can reference them.

| Output | Description |
|---|---|
| `vpc_id` | The ID of the VPC that was created |
| `vpc_cidr` | The IP address range of the VPC |
| `subnet_ids` | Map of tier name → list of subnet IDs (one per AZ) |
| `subnet_ids_by_az` | Map of AZ → list of subnet IDs (one per tier) |
| `subnet_ids_flat` | Simple flat list of all subnet IDs |
| `subnet_cidrs` | Map of each subnet's key to its IP range |
| `route_table_ids` | Map of tier name → list of route table IDs |
| `tgw_attachment_id` | The TGW attachment ID (null if no TGW configured) |
| `tgw_attachment_subnet_ids` | The subnet IDs used to attach to the TGW |
| `resolved_environment_route_table_id` | The TGW route table ID selected for the environment |
| `s3_endpoint_id` | The S3 gateway endpoint ID (null if not enabled) |
| `s3_endpoint_organization_id` | The Organisation ID used in the S3 endpoint policy |
| `dynamodb_endpoint_id` | The DynamoDB gateway endpoint ID (null if not enabled) |
| `resolver_rule_association_ids` | Map of resolver rule ID → association ID (empty if not enabled) |
| `module_version` | The version of this module |

---

## Full Example

A production-ready spoke with all optional features enabled:

```hcl
module "spoke_vpc" {
  source = "../terraform-modules/spoke-vpc"

  name        = "payments-api"
  environment = "prod"
  vpc_cidr    = "10.20.0.0/16"

  # Spread across three AZs with two subnet tiers
  number_of_azs     = 3
  number_of_subnets = 2
  subnet_names      = ["application", "database"]

  # Hub connectivity
  transit_gateway_id = "tgw-0abc123def456"

  environment_route_table_ids = {
    dev     = "tgw-rtb-0dev000"
    test    = "tgw-rtb-0tst000"
    preprod = "tgw-rtb-0pre000"
    prod    = "tgw-rtb-0prd000"
  }

  inspection_route_table_id     = "tgw-rtb-0firewall"
  shared_services_route_table_id = "tgw-rtb-0shared"

  # Gateway endpoints — free, improves performance, restricts to org
  enable_s3_endpoint       = true
  enable_dynamodb_endpoint = true

  # Associate hub DNS forwarding rules automatically
  enable_resolver_rule_associations = true

  tags = {
    Team        = "payments"
    CostCentre  = "CC-1234"
  }
}
```

---

## How Traffic Flows

```
Workload in spoke VPC
        │
        ├─── S3 / DynamoDB traffic ──► Gateway Endpoint ──► AWS service (free, direct)
        │
        └─── All other traffic ──► Transit Gateway ──► Network Firewall (inspection)
                                                              │
                                              ┌───────────────┴────────────────┐
                                              │                                │
                                         Internet                    Other spoke VPCs
                                                                    Shared services
```

All traffic other than S3/DynamoDB is routed via the hub's network firewall before reaching its destination. This ensures consistent security policy enforcement regardless of which spoke account originates the traffic.

---

## Common Questions

**Can I use this module without a Transit Gateway?**
Yes — simply omit `transit_gateway_id` (or leave it as the empty string default). The VPC and subnets will be created but will have no route to external networks.

**What happens if I change `number_of_azs` or `vpc_cidr` after the module has already been applied?**
Changing these values will cause Terraform to destroy and recreate subnets and route tables, which will interrupt any running workloads. Plan these values carefully before first deployment and treat them as immutable.

**Do I need to calculate subnet sizes myself?**
No. The module divides the `vpc_cidr` automatically into equal-sized subnets based on how many AZs and tiers you configure.

**What AWS permissions does this module need?**
At minimum: `ec2:*` for VPC resources, `ram:AcceptResourceShareInvitation` for TGW sharing, and optionally `organizations:DescribeOrganization` if `organization_id` is not supplied explicitly.
