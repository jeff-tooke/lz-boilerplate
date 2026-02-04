# Network Firewall Module

A Terraform module for deploying AWS Network Firewall with multi-region DR support. This module creates firewalls, policies, and rule groups in both primary and DR regions, with comprehensive logging and monitoring.

## Features

- **AWS Network Firewall** deployed across multiple AZs for high availability
- **Firewall Policy** with configurable stateless and stateful rule evaluation
- **Stateless Rule Groups** for high-performance packet filtering
- **Stateful Rule Groups** supporting Suricata-compatible rules
- **Domain-based Filtering** with allowlist/denylist support
- **CloudWatch Logging** for alerts and flow logs
- **Multi-Region DR** with complete rule replication
- **Encryption Support** with customer-managed KMS keys

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Network Firewall Architecture                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   Primary Region (eu-west-1)                DR Region (eu-west-2)          │
│   ┌─────────────────────────────┐          ┌─────────────────────────────┐ │
│   │      Network Firewall       │          │    Network Firewall (DR)    │ │
│   │  ┌─────┐ ┌─────┐ ┌─────┐   │          │  ┌─────┐ ┌─────┐ ┌─────┐   │ │
│   │  │ AZ-a│ │ AZ-b│ │ AZ-c│   │          │  │ AZ-a│ │ AZ-b│ │ AZ-c│   │ │
│   │  │ EP  │ │ EP  │ │ EP  │   │          │  │ EP  │ │ EP  │ │ EP  │   │ │
│   │  └──┬──┘ └──┬──┘ └──┬──┘   │          │  └──┬──┘ └──┬──┘ └──┬──┘   │ │
│   └─────┼───────┼───────┼──────┘          └─────┼───────┼───────┼──────┘ │
│         │       │       │                       │       │       │        │
│   ┌─────▼───────▼───────▼──────┐          ┌─────▼───────▼───────▼──────┐ │
│   │      Firewall Subnets      │          │   Firewall Subnets (DR)    │ │
│   │      (from hub-vpc)        │          │      (from hub-vpc)        │ │
│   └────────────────────────────┘          └────────────────────────────┘ │
│                                                                             │
│   ┌────────────────────────────┐          ┌────────────────────────────┐ │
│   │     Firewall Policy        │          │   Firewall Policy (DR)     │ │
│   │  ┌──────────────────────┐  │          │  ┌──────────────────────┐  │ │
│   │  │  Stateless Rules     │  │          │  │  Stateless Rules     │  │ │
│   │  │  Stateful Rules      │  │          │  │  Stateful Rules      │  │ │
│   │  │  Domain Rules        │  │          │  │  Domain Rules        │  │ │
│   │  └──────────────────────┘  │          │  └──────────────────────┘  │ │
│   └────────────────────────────┘          └────────────────────────────┘ │
│                                                                             │
│   ┌────────────────────────────┐          ┌────────────────────────────┐ │
│   │     CloudWatch Logs        │          │    CloudWatch Logs (DR)    │ │
│   │  - Alert Logs              │          │  - Alert Logs              │ │
│   │  - Flow Logs               │          │  - Flow Logs               │ │
│   └────────────────────────────┘          └────────────────────────────┘ │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

Traffic Flow:
Internet ──▶ IGW ──▶ Firewall Subnet ──▶ [FIREWALL] ──▶ TGW Subnet ──▶ TGW ──▶ Spoke VPCs
```

## Usage

### Basic Example

```hcl
module "network_firewall" {
  source = "./network-firewall"

  name        = "prod-hub"
  environment = "production"

  vpc_id     = module.hub_vpc.vpc_id
  subnet_ids = module.hub_vpc.firewall_subnet_ids_list

  # Simple domain allowlist
  stateful_domain_rule_groups = [
    {
      name        = "allow-aws"
      description = "Allow AWS services"
      priority    = 100
      capacity    = 100
      action      = "ALLOWLIST"
      domain_list = [".amazonaws.com", ".aws.amazon.com"]
    }
  ]

  tags = {
    Project = "core-network"
  }
}
```

### With DR and Custom Rules

```hcl
module "network_firewall" {
  source = "./network-firewall"

  name        = "prod-hub"
  environment = "production"

  # Primary region
  vpc_id     = module.hub_vpc.vpc_id
  subnet_ids = module.hub_vpc.firewall_subnet_ids_list

  # Policy configuration
  policy_stateful_rule_order       = "STRICT_ORDER"
  policy_stateless_default_actions = ["aws:forward_to_sfe"]
  policy_stateful_default_actions  = ["aws:drop_established", "aws:alert_established"]

  # Stateless rules
  stateless_rule_groups = [
    {
      name        = "drop-invalid"
      description = "Drop invalid packets"
      priority    = 100
      capacity    = 100
      rules = [
        {
          priority = 1
          actions  = ["aws:drop"]
          match = {
            protocols         = [1]  # ICMP
            source_cidrs      = ["0.0.0.0/0"]
            destination_cidrs = ["10.0.0.0/8"]
          }
        }
      ]
    }
  ]

  # Stateful rules (Suricata format)
  stateful_rule_groups = [
    {
      name        = "security-rules"
      description = "Security enforcement rules"
      priority    = 100
      capacity    = 1000
      rules       = <<-EOT
        # Allow established connections
        pass tcp $HOME_NET any <> any any (flow:established; sid:1; rev:1;)

        # Block suspicious patterns
        drop http any any -> $HOME_NET any (msg:"Blocked request"; content:"malicious"; sid:2; rev:1;)
      EOT
    }
  ]

  # Domain filtering
  stateful_domain_rule_groups = [
    {
      name        = "allow-aws"
      description = "Allow AWS services"
      priority    = 200
      capacity    = 100
      action      = "ALLOWLIST"
      domain_list = [".amazonaws.com"]
    }
  ]

  # DR configuration
  dr_enabled    = true
  dr_region     = "eu-west-2"
  dr_vpc_id     = module.hub_vpc.dr_vpc_id
  dr_subnet_ids = module.hub_vpc.dr_firewall_subnet_ids_list

  tags = {
    Project = "core-network"
  }
}
```

### Routing Traffic Through the Firewall

The firewall endpoints must be used as next-hop in route tables:

```hcl
# Route from TGW subnets to internet via firewall
resource "aws_route" "tgw_to_internet" {
  for_each = module.hub_vpc.tgw_attachment_route_table_ids

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id        = module.network_firewall.firewall_endpoint_ids[each.key]
}

# Route from firewall subnets to NAT Gateway
resource "aws_route" "firewall_to_nat" {
  for_each = module.hub_vpc.firewall_route_table_ids

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = module.hub_vpc.nat_gateway_ids[each.key]
}
```

## Inputs

### General

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name prefix for resources | `string` | n/a | yes |
| environment | Environment name | `string` | n/a | yes |
| tags | Additional tags | `map(string)` | `{}` | no |

### Firewall Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_id | VPC ID for firewall | `string` | n/a | yes |
| subnet_ids | Firewall subnet IDs | `list(string)` | n/a | yes |
| firewall_policy_arn | Existing policy ARN (creates new if empty) | `string` | `""` | no |

### Policy Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| policy_stateless_default_actions | Default stateless actions | `list(string)` | `["aws:forward_to_sfe"]` | no |
| policy_stateless_fragment_default_actions | Default fragment actions | `list(string)` | `["aws:forward_to_sfe"]` | no |
| policy_stateful_default_actions | Default stateful actions (STRICT_ORDER only) | `list(string)` | `["aws:drop_established", "aws:alert_established"]` | no |
| policy_stateful_rule_order | Rule order: STRICT_ORDER or DEFAULT_ACTION_ORDER | `string` | `"STRICT_ORDER"` | no |

### Rule Groups

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| stateless_rule_groups | Stateless rule group configurations | `list(object)` | `[]` | no |
| stateful_rule_groups | Stateful rule groups (Suricata rules) | `list(object)` | `[]` | no |
| stateful_domain_rule_groups | Domain-based rule groups | `list(object)` | `[]` | no |

### Logging

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| logging_enabled | Enable firewall logging | `bool` | `true` | no |
| alert_log_destination_type | Alert log destination type | `string` | `"CloudWatchLogs"` | no |
| flow_log_destination_type | Flow log destination type | `string` | `"CloudWatchLogs"` | no |
| log_retention_days | Log retention period | `number` | `30` | no |

### Protection

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| delete_protection | Enable deletion protection | `bool` | `false` | no |
| subnet_change_protection | Enable subnet change protection | `bool` | `false` | no |
| firewall_policy_change_protection | Enable policy change protection | `bool` | `false` | no |

### DR Configuration

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| dr_enabled | Enable DR deployment | `bool` | `false` | no |
| dr_region | DR region | `string` | `""` | when dr_enabled |
| dr_vpc_id | DR VPC ID | `string` | `""` | when dr_enabled |
| dr_subnet_ids | DR firewall subnet IDs | `list(string)` | `[]` | when dr_enabled |

## Outputs

### Primary Region

| Name | Description |
|------|-------------|
| firewall_id | Firewall ID |
| firewall_arn | Firewall ARN |
| firewall_endpoint_ids | Map of AZ to endpoint ID (for routing) |
| firewall_endpoint_ids_by_subnet | Map of subnet ID to endpoint ID |
| firewall_policy_arn | Policy ARN |
| alert_log_group_name | Alert log group name |
| flow_log_group_name | Flow log group name |

### DR Region

| Name | Description |
|------|-------------|
| dr_firewall_id | DR firewall ID |
| dr_firewall_arn | DR firewall ARN |
| dr_firewall_endpoint_ids | Map of AZ to DR endpoint ID |
| dr_firewall_policy_arn | DR policy ARN |

## Rule Group Formats

### Stateless Rules

```hcl
stateless_rule_groups = [
  {
    name        = "example"
    description = "Example stateless rules"
    priority    = 100
    capacity    = 100
    rules = [
      {
        priority = 1
        actions  = ["aws:drop"]  # or "aws:pass", "aws:forward_to_sfe"
        match = {
          protocols         = [6]              # TCP=6, UDP=17, ICMP=1
          source_cidrs      = ["0.0.0.0/0"]
          destination_cidrs = ["10.0.0.0/8"]
          source_ports      = [{ from = 0, to = 65535 }]
          destination_ports = [{ from = 22, to = 22 }]
        }
      }
    ]
  }
]
```

### Stateful Rules (Suricata)

```hcl
stateful_rule_groups = [
  {
    name        = "example"
    description = "Example Suricata rules"
    priority    = 100
    capacity    = 1000
    rules       = <<-EOT
      # Alert on SSH connections
      alert ssh any any -> $HOME_NET 22 (msg:"SSH connection"; sid:1; rev:1;)

      # Drop malicious traffic
      drop tcp any any -> $HOME_NET any (msg:"Blocked"; content:"malware"; sid:2; rev:1;)

      # Allow established
      pass tcp $HOME_NET any <> any any (flow:established; sid:3; rev:1;)
    EOT
  }
]
```

### Domain Rules

```hcl
stateful_domain_rule_groups = [
  {
    name           = "allow-trusted"
    description    = "Allow trusted domains"
    priority       = 100
    capacity       = 100
    action         = "ALLOWLIST"  # or "DENYLIST"
    protocols      = ["HTTP_HOST", "TLS_SNI"]
    home_net_cidrs = ["10.0.0.0/8"]
    domain_list    = [".example.com", "api.trusted.com"]
  }
]
```

## Version Requirements

| Requirement | Version |
|-------------|---------|
| Terraform | >= 1.5.0, < 2.0.0 |
| AWS Provider | >= 5.0, < 6.0 |
| Module Version | 1.0.0 |

## Important Notes

1. **Firewall Endpoints**: Each AZ gets its own firewall endpoint. You must route traffic through the correct endpoint based on AZ for symmetric routing.

2. **Rule Capacity**: Plan capacity carefully - it cannot be changed after creation. Suricata rules typically need more capacity than domain rules.

3. **STRICT_ORDER Mode**: Recommended for explicit control. Rules are evaluated in priority order and first match wins.

4. **DR Considerations**: Rule groups are regional resources and must be created in each region. This module handles that automatically.

5. **Logging Costs**: Flow logs can generate significant data. Consider S3 with lifecycle policies for high-traffic environments.
