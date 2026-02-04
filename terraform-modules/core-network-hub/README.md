# Core Network Hub Module

Orchestration module that deploys a complete hub network for a hub-and-spoke architecture. This module combines the `hub-vpc` and `vpc-endpoints` modules and provides a single entry point for deploying core networking infrastructure with multi-region DR support.

## Features

- Single entry point for complete hub network deployment
- VPC with 4 subnet tiers (firewall, TGW attachment, egress, endpoints) across 3 AZs
- VPC endpoints with automatic gateway/interface type detection
- Multi-region DR support controlled by a single `dr_enabled` flag
- Consistent tagging with module version tracking
- Prepared for future firewall and transit gateway integration

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           core-network-hub                                  │
│                          dr_enabled = true/false                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Primary Region (e.g., eu-west-1)       DR Region (e.g., eu-west-2)        │
│  ┌─────────────────────────────┐        ┌─────────────────────────────┐    │
│  │         hub-vpc             │        │         hub-vpc (DR)        │    │
│  │  ┌─────────────────────┐    │        │  ┌─────────────────────┐    │    │
│  │  │ Firewall Subnets    │    │        │  │ Firewall Subnets    │    │    │
│  │  │ TGW Attach Subnets  │    │        │  │ TGW Attach Subnets  │    │    │
│  │  │ Egress Subnets      │    │        │  │ Egress Subnets      │    │    │
│  │  │ Endpoint Subnets    │    │        │  │ Endpoint Subnets    │    │    │
│  │  │ NAT Gateways (3x)   │    │        │  │ NAT Gateways (3x)   │    │    │
│  │  └─────────────────────┘    │        │  └─────────────────────┘    │    │
│  └─────────────────────────────┘        └─────────────────────────────┘    │
│                                                                             │
│  ┌─────────────────────────────┐        ┌─────────────────────────────┐    │
│  │      vpc-endpoints          │        │    vpc-endpoints (DR)       │    │
│  │  Gateway: S3, DynamoDB      │        │  Gateway: S3, DynamoDB      │    │
│  │  Interface: SSM, KMS, etc.  │        │  Interface: SSM, KMS, etc.  │    │
│  └─────────────────────────────┘        └─────────────────────────────┘    │
│                                                                             │
│  ┌─────────────────────────────┐        ┌─────────────────────────────┐    │
│  │  network-firewall (future)  │        │  network-firewall (future)  │    │
│  └─────────────────────────────┘        └─────────────────────────────┘    │
│                                                                             │
│  ┌─────────────────────────────┐        ┌─────────────────────────────┐    │
│  │  transit-gateway (future)   │        │  transit-gateway (future)   │    │
│  └─────────────────────────────┘        └─────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Example (Single Region)

```hcl
module "hub_network" {
  source = "./core-network-hub"

  name           = "prod-hub"
  environment    = "production"
  primary_region = "eu-west-1"

  vpc_cidr           = "10.0.0.0/20"
  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  firewall_subnet_cidrs       = ["10.0.0.0/28", "10.0.0.16/28", "10.0.0.32/28"]
  tgw_attachment_subnet_cidrs = ["10.0.0.48/28", "10.0.0.64/28", "10.0.0.80/28"]
  egress_subnet_cidrs         = ["10.0.0.96/28", "10.0.0.112/28", "10.0.0.128/28"]
  endpoint_subnet_cidrs       = ["10.0.1.0/25", "10.0.1.128/25", "10.0.2.0/25"]

  endpoints = [
    "com.amazonaws.eu-west-1.s3",
    "com.amazonaws.eu-west-1.ssm",
    "com.amazonaws.eu-west-1.kms"
  ]

  tags = {
    Project = "core-network"
  }
}
```

### Multi-Region DR Deployment

```hcl
module "hub_network" {
  source = "./core-network-hub"

  name           = "prod-hub"
  environment    = "production"
  primary_region = "eu-west-1"

  # Primary region
  vpc_cidr           = "10.0.0.0/20"
  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  firewall_subnet_cidrs       = ["10.0.0.0/28", "10.0.0.16/28", "10.0.0.32/28"]
  tgw_attachment_subnet_cidrs = ["10.0.0.48/28", "10.0.0.64/28", "10.0.0.80/28"]
  egress_subnet_cidrs         = ["10.0.0.96/28", "10.0.0.112/28", "10.0.0.128/28"]
  endpoint_subnet_cidrs       = ["10.0.1.0/25", "10.0.1.128/25", "10.0.2.0/25"]

  endpoints = [
    "com.amazonaws.eu-west-1.s3",
    "com.amazonaws.eu-west-1.dynamodb",
    "com.amazonaws.eu-west-1.ssm",
    "com.amazonaws.eu-west-1.kms"
  ]

  # DR region (enabled with single flag)
  dr_enabled            = true
  dr_region             = "eu-west-2"
  dr_vpc_cidr           = "10.1.0.0/20"
  dr_availability_zones = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]

  dr_firewall_subnet_cidrs       = ["10.1.0.0/28", "10.1.0.16/28", "10.1.0.32/28"]
  dr_tgw_attachment_subnet_cidrs = ["10.1.0.48/28", "10.1.0.64/28", "10.1.0.80/28"]
  dr_egress_subnet_cidrs         = ["10.1.0.96/28", "10.1.0.112/28", "10.1.0.128/28"]
  dr_endpoint_subnet_cidrs       = ["10.1.1.0/25", "10.1.1.128/25", "10.1.2.0/25"]

  dr_endpoints = [
    "com.amazonaws.eu-west-2.s3",
    "com.amazonaws.eu-west-2.dynamodb",
    "com.amazonaws.eu-west-2.ssm",
    "com.amazonaws.eu-west-2.kms"
  ]

  tags = {
    Project = "core-network"
  }
}
```

## Inputs

### General

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Name prefix for all resources | `string` | n/a | yes |
| environment | Environment name (prod, nonprod) | `string` | n/a | yes |
| primary_region | Primary AWS region | `string` | n/a | yes |
| tags | Additional tags for all resources | `map(string)` | `{}` | no |

### Primary Region VPC

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_cidr | CIDR block for the primary VPC | `string` | n/a | yes |
| availability_zones | List of 3 AZs for HA | `list(string)` | n/a | yes |
| firewall_subnet_cidrs | List of 3 /28 CIDRs for firewall subnets | `list(string)` | n/a | yes |
| tgw_attachment_subnet_cidrs | List of 3 /28 CIDRs for TGW attachment subnets | `list(string)` | n/a | yes |
| egress_subnet_cidrs | List of 3 /28 CIDRs for egress subnets | `list(string)` | n/a | yes |
| endpoint_subnet_cidrs | List of 3 /25 CIDRs for endpoint subnets | `list(string)` | n/a | yes |

### VPC Endpoints

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| endpoints | List of VPC endpoint service names | `list(string)` | `[]` | no |
| endpoint_security_group_ids | Custom security groups for endpoints | `list(string)` | `[]` | no |
| create_default_endpoint_security_group | Create default SG if none provided | `bool` | `true` | no |
| private_dns_enabled | Enable private DNS for interface endpoints | `bool` | `true` | no |
| endpoint_tags | Per-endpoint additional tags | `map(map(string))` | `{}` | no |

### DNS

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| enable_dns_hostnames | Enable DNS hostnames in VPC | `bool` | `true` | no |
| enable_dns_support | Enable DNS support in VPC | `bool` | `true` | no |

### DR Region

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| dr_enabled | Enable DR region deployment | `bool` | `false` | no |
| dr_region | DR region | `string` | `""` | when dr_enabled |
| dr_vpc_cidr | CIDR for DR VPC | `string` | `""` | when dr_enabled |
| dr_availability_zones | List of 3 AZs in DR region | `list(string)` | `[]` | when dr_enabled |
| dr_firewall_subnet_cidrs | DR firewall subnet CIDRs | `list(string)` | `[]` | when dr_enabled |
| dr_tgw_attachment_subnet_cidrs | DR TGW attachment subnet CIDRs | `list(string)` | `[]` | when dr_enabled |
| dr_egress_subnet_cidrs | DR egress subnet CIDRs | `list(string)` | `[]` | when dr_enabled |
| dr_endpoint_subnet_cidrs | DR endpoint subnet CIDRs | `list(string)` | `[]` | when dr_enabled |
| dr_endpoints | DR endpoint service names | `list(string)` | `[]` | when dr_enabled |
| dr_endpoint_security_group_ids | DR endpoint security groups | `list(string)` | `[]` | no |

## Outputs

### Primary Region

| Name | Description |
|------|-------------|
| module_version | Version of the core-network-hub module |
| vpc_id | ID of the primary hub VPC |
| vpc_cidr | CIDR block of the primary VPC |
| firewall_subnet_ids | Map of AZ to firewall subnet ID |
| tgw_attachment_subnet_ids | Map of AZ to TGW attachment subnet ID |
| egress_subnet_ids | Map of AZ to egress subnet ID |
| endpoint_subnet_ids | Map of AZ to endpoint subnet ID |
| nat_gateway_ids | Map of AZ to NAT Gateway ID |
| gateway_endpoints | Map of gateway endpoint details |
| interface_endpoints | Map of interface endpoint details |
| all_endpoint_ids | List of all endpoint IDs |

### DR Region

| Name | Description |
|------|-------------|
| dr_vpc_id | ID of the DR hub VPC (null if DR not enabled) |
| dr_vpc_cidr | CIDR block of the DR VPC |
| dr_firewall_subnet_ids | Map of AZ to DR firewall subnet ID |
| dr_tgw_attachment_subnet_ids | Map of AZ to DR TGW attachment subnet ID |
| dr_egress_subnet_ids | Map of AZ to DR egress subnet ID |
| dr_endpoint_subnet_ids | Map of AZ to DR endpoint subnet ID |
| dr_nat_gateway_ids | Map of AZ to DR NAT Gateway ID |
| dr_gateway_endpoints | Map of DR gateway endpoint details |
| dr_interface_endpoints | Map of DR interface endpoint details |
| dr_all_endpoint_ids | List of all DR endpoint IDs |

## Version Requirements

| Requirement | Version |
|-------------|---------|
| Terraform | >= 1.5.0, < 2.0.0 |
| AWS Provider | >= 5.0, < 6.0 |

## Module Versions

All child modules maintain consistent version tags:

| Module | Version |
|--------|---------|
| core-network-hub | 1.0.0 |
| hub-vpc | 1.0.0 |
| vpc-endpoints | 1.0.0 |

Resources are tagged with `ModuleVersion` for tracking deployed versions.

## Future Enhancements

The module includes placeholder configurations for:

- **Network Firewall**: AWS Network Firewall deployment in firewall subnets
- **Transit Gateway**: TGW creation or attachment with VPC attachments

These will be implemented as separate modules following the same DR pattern.
