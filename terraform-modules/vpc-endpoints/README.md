# VPC Endpoints Module

A modular Terraform module that provisions AWS VPC endpoints based on a list of full service names. Supports multi-region deployment with a DR (Disaster Recovery) feature flag.

## Features

- Automatic detection of gateway vs interface endpoint types
- Default security group creation for interface endpoints
- Multi-region DR support with `dr_enabled` feature flag
- Per-endpoint tagging support

## Usage

### Basic Example

```hcl
module "vpc_endpoints" {
  source = "./vpc-endpoints"

  vpc_id          = "vpc-12345678"
  subnet_ids      = ["subnet-111", "subnet-222"]
  route_table_ids = ["rtb-111", "rtb-222"]

  endpoints = [
    "com.amazonaws.ap-southeast-2.s3",
    "com.amazonaws.ap-southeast-2.dynamodb",
    "com.amazonaws.ap-southeast-2.ssm",
    "com.amazonaws.ap-southeast-2.ssmmessages",
    "com.amazonaws.ap-southeast-2.ec2messages",
    "com.amazonaws.ap-southeast-2.sts",
    "com.amazonaws.ap-southeast-2.secretsmanager",
    "com.amazonaws.ap-southeast-2.kms",
    "com.amazonaws.ap-southeast-2.logs"
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### Adding New Endpoints

Add the full AWS VPC endpoint service name to the `endpoints` list:

```hcl
endpoints = [
  # Existing
  "com.amazonaws.ap-southeast-2.s3",
  "com.amazonaws.ap-southeast-2.ssm",
  "com.amazonaws.ap-southeast-2.sts",

  # New additions
  "com.amazonaws.ap-southeast-2.secretsmanager",
  "com.amazonaws.ap-southeast-2.ecr.api",
  "com.amazonaws.ap-southeast-2.ecr.dkr",
  "com.amazonaws.ap-southeast-2.sqs",
  "com.amazonaws.ap-southeast-2.sns"
]
```

### Common Endpoint Sets

**SSM Session Manager:**
```hcl
endpoints = [
  "com.amazonaws.ap-southeast-2.ssm",
  "com.amazonaws.ap-southeast-2.ssmmessages",
  "com.amazonaws.ap-southeast-2.ec2messages",
  "com.amazonaws.ap-southeast-2.s3",
  "com.amazonaws.ap-southeast-2.kms"
]
```

**ECS/Fargate:**
```hcl
endpoints = [
  "com.amazonaws.ap-southeast-2.ecr.api",
  "com.amazonaws.ap-southeast-2.ecr.dkr",
  "com.amazonaws.ap-southeast-2.s3",
  "com.amazonaws.ap-southeast-2.logs",
  "com.amazonaws.ap-southeast-2.ecs",
  "com.amazonaws.ap-southeast-2.ecs-agent",
  "com.amazonaws.ap-southeast-2.ecs-telemetry"
]
```

**Lambda in VPC:**
```hcl
endpoints = [
  "com.amazonaws.ap-southeast-2.lambda",
  "com.amazonaws.ap-southeast-2.sts",
  "com.amazonaws.ap-southeast-2.logs",
  "com.amazonaws.ap-southeast-2.s3"
]
```

### Using Custom Security Groups

```hcl
module "vpc_endpoints" {
  source = "./vpc-endpoints"

  vpc_id             = "vpc-12345678"
  subnet_ids         = ["subnet-111", "subnet-222"]
  route_table_ids    = ["rtb-111"]
  security_group_ids = [aws_security_group.custom.id]

  endpoints = [
    "com.amazonaws.ap-southeast-2.ssm",
    "com.amazonaws.ap-southeast-2.secretsmanager"
  ]
}
```

### Multi-Region DR Deployment

Enable the `dr_enabled` flag to deploy endpoints in a secondary region:

```hcl
module "vpc_endpoints" {
  source = "./vpc-endpoints"

  # Primary region configuration
  vpc_id          = module.hub_vpc.vpc_id
  subnet_ids      = module.hub_vpc.endpoint_subnet_ids_list
  route_table_ids = values(module.hub_vpc.endpoint_route_table_ids)

  endpoints = [
    "com.amazonaws.eu-west-1.s3",
    "com.amazonaws.eu-west-1.dynamodb",
    "com.amazonaws.eu-west-1.ssm",
    "com.amazonaws.eu-west-1.ssmmessages",
    "com.amazonaws.eu-west-1.ec2messages",
    "com.amazonaws.eu-west-1.sts",
    "com.amazonaws.eu-west-1.kms",
    "com.amazonaws.eu-west-1.logs"
  ]

  # DR region configuration
  dr_enabled         = true
  dr_region          = "eu-west-2"
  dr_vpc_id          = module.hub_vpc.dr_vpc_id
  dr_subnet_ids      = module.hub_vpc.dr_endpoint_subnet_ids_list
  dr_route_table_ids = values(module.hub_vpc.dr_endpoint_route_table_ids)

  # DR endpoints must use the DR region in service names
  dr_endpoints = [
    "com.amazonaws.eu-west-2.s3",
    "com.amazonaws.eu-west-2.dynamodb",
    "com.amazonaws.eu-west-2.ssm",
    "com.amazonaws.eu-west-2.ssmmessages",
    "com.amazonaws.eu-west-2.ec2messages",
    "com.amazonaws.eu-west-2.sts",
    "com.amazonaws.eu-west-2.kms",
    "com.amazonaws.eu-west-2.logs"
  ]

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

## Inputs

### Primary Region

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_id | The ID of the VPC | `string` | n/a | yes |
| endpoints | List of full AWS VPC endpoint service names | `list(string)` | `[]` | no |
| subnet_ids | Subnet IDs for interface endpoints | `list(string)` | `[]` | no |
| route_table_ids | Route table IDs for gateway endpoints | `list(string)` | `[]` | no |
| security_group_ids | Security groups for interface endpoints | `list(string)` | `[]` | no |
| create_default_security_group | Create default SG if none provided | `bool` | `true` | no |
| private_dns_enabled | Enable private DNS for interface endpoints | `bool` | `true` | no |
| tags | Tags for all resources | `map(string)` | `{}` | no |
| endpoint_tags | Per-endpoint additional tags | `map(map(string))` | `{}` | no |

### DR Region

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| dr_enabled | Feature flag to enable DR region deployment | `bool` | `false` | no |
| dr_region | DR region for endpoint deployment | `string` | `""` | when dr_enabled |
| dr_vpc_id | The ID of the DR VPC | `string` | `""` | when dr_enabled |
| dr_endpoints | List of full AWS VPC endpoint service names for DR region | `list(string)` | `[]` | when dr_enabled |
| dr_subnet_ids | Subnet IDs for DR interface endpoints | `list(string)` | `[]` | when dr_enabled |
| dr_route_table_ids | Route table IDs for DR gateway endpoints | `list(string)` | `[]` | when dr_enabled |
| dr_security_group_ids | Security groups for DR interface endpoints | `list(string)` | `[]` | no |

## Outputs

### Primary Region

| Name | Description |
|------|-------------|
| gateway_endpoints | Map of gateway endpoint details |
| interface_endpoints | Map of interface endpoint details |
| all_endpoint_ids | List of all endpoint IDs |
| security_group_id | Default security group ID (if created) |
| endpoint_dns_entries | Map of service names to DNS entries |

### DR Region

| Name | Description |
|------|-------------|
| dr_gateway_endpoints | Map of DR gateway endpoint details (empty if DR not enabled) |
| dr_interface_endpoints | Map of DR interface endpoint details (empty if DR not enabled) |
| dr_all_endpoint_ids | List of all DR endpoint IDs (empty if DR not enabled) |
| dr_security_group_id | DR default security group ID (null if not created) |
| dr_endpoint_dns_entries | Map of DR service names to DNS entries (empty if DR not enabled) |

## Service Name Format

All endpoint service names must use the full AWS VPC endpoint service name format:

```
com.amazonaws.<region>.<service>
```

The module automatically detects the endpoint type:

**Gateway Endpoints (route table based):**
- `com.amazonaws.<region>.s3`
- `com.amazonaws.<region>.dynamodb`

**Interface Endpoints (ENI based):**
- `com.amazonaws.<region>.ssm`
- `com.amazonaws.<region>.ssmmessages`
- `com.amazonaws.<region>.ec2messages`
- `com.amazonaws.<region>.sts`
- `com.amazonaws.<region>.kms`
- `com.amazonaws.<region>.secretsmanager`
- `com.amazonaws.<region>.logs`
- `com.amazonaws.<region>.monitoring`
- `com.amazonaws.<region>.events`
- `com.amazonaws.<region>.ecr.api`
- `com.amazonaws.<region>.ecr.dkr`
- `com.amazonaws.<region>.ecs`
- `com.amazonaws.<region>.ecs-agent`
- `com.amazonaws.<region>.ecs-telemetry`
- `com.amazonaws.<region>.sqs`
- `com.amazonaws.<region>.sns`
- `com.amazonaws.<region>.lambda`
- `com.amazonaws.<region>.rds`
- `com.amazonaws.<region>.elasticache`
- `com.amazonaws.<region>.elasticfilesystem`
- `com.amazonaws.<region>.execute-api`
- `com.amazonaws.<region>.athena`
- `com.amazonaws.<region>.glue`
- `com.amazonaws.<region>.bedrock`
- `com.amazonaws.<region>.bedrock-runtime`
- And any other valid AWS VPC endpoint service...

You can find the full list of available VPC endpoint services in the [AWS documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/aws-services-privatelink-support.html) or by running:

```bash
aws ec2 describe-vpc-endpoint-services --region <region> --query 'ServiceNames'
```
