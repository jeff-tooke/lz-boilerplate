# Core Network Module

Terraform module for deploying a core hub VPC as part of a hub-and-spoke network architecture. Designed to be called multiple times for different system-domain workloads (e.g., IT and OT hubs).

## Architecture

This module creates a hub VPC with the following subnet tiers across 3 Availability Zones for high availability:

| Subnet Type    | Size          | Count | Purpose                           |
| -------------- | ------------- | ----- | --------------------------------- |
| Firewall       | /28 (16 IPs)  | 3     | AWS Network Firewall endpoints    |
| TGW Attachment | /28 (16 IPs)  | 3     | Transit Gateway attachments       |
| Egress         | /28 (16 IPs)  | 3     | NAT Gateways for outbound traffic |
| Endpoints      | /25 (128 IPs) | 3     | VPC interface endpoints           |

Each subnet tier has dedicated route tables for granular routing control.

## Usage

### Standard Deployment (Single Region)

```hcl
module "hub_vpc_production" {
  source = "./core-network"

  name        = "prod-hub"
  environment = "production"
  vpc_cidr    = "10.0.0.0/20"

  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  # /28 subnets (16 IPs each, 11 usable)
  firewall_subnet_cidrs = [
    "10.0.0.0/28",
    "10.0.0.16/28",
    "10.0.0.32/28"
  ]

  tgw_attachment_subnet_cidrs = [
    "10.0.0.48/28",
    "10.0.0.64/28",
    "10.0.0.80/28"
  ]

  egress_subnet_cidrs = [
    "10.0.0.96/28",
    "10.0.0.112/28",
    "10.0.0.128/28"
  ]

  # /25 subnets (128 IPs each, 123 usable)
  endpoint_subnet_cidrs = [
    "10.0.1.0/25",
    "10.0.1.128/25",
    "10.0.2.0/25"
  ]

  tags = {
    Project = "core-network"
    Domain  = "production"
  }
}
```

### DR Deployment (Multi-Region)

When `dr_enabled = true`, the module deploys an identical VPC in the DR region with separate CIDR ranges. All DR resources have `-dr` appended to their names for clear identification.

```hcl
module "hub_vpc_production" {
  source = "./core-network"

  name        = "prod-hub"
  environment = "production"
  vpc_cidr    = "10.0.0.0/20"

  availability_zones = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]

  # Primary region subnets
  firewall_subnet_cidrs = [
    "10.0.0.0/28",
    "10.0.0.16/28",
    "10.0.0.32/28"
  ]

  tgw_attachment_subnet_cidrs = [
    "10.0.0.48/28",
    "10.0.0.64/28",
    "10.0.0.80/28"
  ]

  egress_subnet_cidrs = [
    "10.0.0.96/28",
    "10.0.0.112/28",
    "10.0.0.128/28"
  ]

  endpoint_subnet_cidrs = [
    "10.0.1.0/25",
    "10.0.1.128/25",
    "10.0.2.0/25"
  ]

  # DR configuration
  dr_enabled            = true
  dr_region             = "eu-west-2"
  dr_vpc_cidr           = "10.1.0.0/20"  # Different CIDR range for DR
  dr_availability_zones = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]

  # DR region subnets (must not overlap with primary)
  dr_firewall_subnet_cidrs = [
    "10.1.0.0/28",
    "10.1.0.16/28",
    "10.1.0.32/28"
  ]

  dr_tgw_attachment_subnet_cidrs = [
    "10.1.0.48/28",
    "10.1.0.64/28",
    "10.1.0.80/28"
  ]

  dr_egress_subnet_cidrs = [
    "10.1.0.96/28",
    "10.1.0.112/28",
    "10.1.0.128/28"
  ]

  dr_endpoint_subnet_cidrs = [
    "10.1.1.0/25",
    "10.1.1.128/25",
    "10.1.2.0/25"
  ]

  tags = {
    Project = "core-network"
    Domain  = "production"
  }
}
```

### Multiple Hub VPCs

Call the module multiple times with different configurations for separate system domains:

```hcl
# Production hub
module "hub_vpc_production" {
  source      = "./core-network"
  name        = "prod-hub"
  environment = "production"
  vpc_cidr    = "10.0.0.0/20"
  # ... subnet configurations
}

# Non-production hub
module "hub_vpc_nonproduction" {
  source      = "./core-network"
  name        = "nonprod-hub"
  environment = "nonproduction"
  vpc_cidr    = "10.2.0.0/20"  # Different CIDR range
  # ... subnet configurations
}
```

## DR vs Non-DR Comparison

| Aspect          | Standard (dr_enabled = false) | DR (dr_enabled = true)                                               |
| --------------- | ----------------------------- | -------------------------------------------------------------------- |
| Regions         | Single primary region         | Primary + DR region                                                  |
| VPCs            | 1                             | 2                                                                    |
| NAT Gateways    | 3 (one per AZ)                | 6 (3 per region)                                                     |
| CIDR Planning   | Single range                  | Non-overlapping ranges required                                      |
| Resource Naming | `{name}-{resource}-{az}`      | Primary: `{name}-{resource}-{az}`<br>DR: `{name}-{resource}-{az}-dr` |
| Cost            | Lower                         | Higher (2x most resources)                                           |

## CIDR Planning

When planning CIDR blocks, ensure:

1. **Primary and DR VPCs do not overlap** - Required for potential VPC peering or Transit Gateway connectivity between regions
2. **Different hub VPCs do not overlap** - Each hub (prod, nonprod) needs unique ranges
3. **Allow room for growth** - Use a /20 or larger for the VPC to accommodate future subnets

### Example CIDR Allocation

| Hub            | Region              | VPC CIDR    |
| -------------- | ------------------- | ----------- |
| Production     | Primary (eu-west-1) | 10.0.0.0/20 |
| Production     | DR (eu-west-2)      | 10.1.0.0/20 |
| Non-Production | Primary (eu-west-1) | 10.2.0.0/20 |
| Non-Production | DR (eu-west-2)      | 10.3.0.0/20 |

## Inputs

| Name                          | Description                              | Type           | Required              |
| ----------------------------- | ---------------------------------------- | -------------- | --------------------- |
| `name`                        | Name prefix for the hub VPC              | `string`       | Yes                   |
| `environment`                 | Environment name (e.g., prod, nonprod)   | `string`       | Yes                   |
| `vpc_cidr`                    | CIDR block for the VPC                   | `string`       | Yes                   |
| `availability_zones`          | List of 3 AZs for HA                     | `list(string)` | Yes                   |
| `firewall_subnet_cidrs`       | List of 3 /28 CIDRs for firewall subnets | `list(string)` | Yes                   |
| `tgw_attachment_subnet_cidrs` | List of 3 /28 CIDRs for TGW subnets      | `list(string)` | Yes                   |
| `egress_subnet_cidrs`         | List of 3 /28 CIDRs for egress subnets   | `list(string)` | Yes                   |
| `endpoint_subnet_cidrs`       | List of 3 /25 CIDRs for endpoint subnets | `list(string)` | Yes                   |
| `dr_enabled`                  | Enable DR region deployment              | `bool`         | No (default: `false`) |
| `dr_region`                   | DR region (required if dr_enabled)       | `string`       | No                    |
| `dr_vpc_cidr`                 | DR VPC CIDR (required if dr_enabled)     | `string`       | No                    |
| `dr_availability_zones`       | DR AZs (required if dr_enabled)          | `list(string)` | No                    |
| `dr_*_subnet_cidrs`           | DR subnet CIDRs (required if dr_enabled) | `list(string)` | No                    |
| `tags`                        | Additional tags for all resources        | `map(string)`  | No                    |

## Outputs

### Primary Region

| Name                        | Description                           |
| --------------------------- | ------------------------------------- |
| `vpc_id`                    | ID of the hub VPC                     |
| `vpc_cidr`                  | CIDR block of the VPC                 |
| `firewall_subnet_ids`       | Map of AZ to firewall subnet ID       |
| `tgw_attachment_subnet_ids` | Map of AZ to TGW attachment subnet ID |
| `egress_subnet_ids`         | Map of AZ to egress subnet ID         |
| `endpoint_subnet_ids`       | Map of AZ to endpoint subnet ID       |
| `nat_gateway_ids`           | Map of AZ to NAT Gateway ID           |
| `*_subnet_ids_list`         | List versions of subnet IDs           |

### DR Region (only when dr_enabled = true)

| Name                           | Description                              |
| ------------------------------ | ---------------------------------------- |
| `dr_vpc_id`                    | ID of the DR hub VPC                     |
| `dr_vpc_cidr`                  | CIDR block of the DR VPC                 |
| `dr_firewall_subnet_ids`       | Map of AZ to DR firewall subnet ID       |
| `dr_tgw_attachment_subnet_ids` | Map of AZ to DR TGW attachment subnet ID |
| `dr_egress_subnet_ids`         | Map of AZ to DR egress subnet ID         |
| `dr_endpoint_subnet_ids`       | Map of AZ to DR endpoint subnet ID       |
| `dr_nat_gateway_ids`           | Map of AZ to DR NAT Gateway ID           |

## Resource Naming Convention

All resources follow a consistent naming pattern:

**Primary Region:**

- VPC: `{name}-hub-vpc`
- Subnets: `{name}-{tier}-{az}` (e.g., `prod-hub-firewall-eu-west-1a`)
- Route Tables: `{name}-{tier}-{az}-rt`
- NAT Gateways: `{name}-nat-{az}`

**DR Region:**

- VPC: `{name}-hub-vpc-dr`
- Subnets: `{name}-{tier}-{az}-dr` (e.g., `prod-hub-firewall-eu-west-2a-dr`)
- Route Tables: `{name}-{tier}-{az}-dr-rt`
- NAT Gateways: `{name}-nat-{az}-dr`

## Requirements

| Name      | Version  |
| --------- | -------- |
| terraform | >= 1.5.0 |
| aws       | >= 5.0   |
