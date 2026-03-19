# workload-asg

> **DEMO CODE — NOT FOR PRODUCTION USE**
>
> This module is provided as a demonstration of AWS Auto Scaling Group patterns
> within a Landing Zone boilerplate. It is intentionally simplified and has **not**
> been hardened, security-reviewed, or tested for real-world workloads. Do not
> deploy this module in a production environment or any environment handling
> real data without a thorough review and significant rework.

---

## What this module does

Deploys an Auto Scaling Group across 2+ Availability Zones into an existing VPC.
Supports Amazon Linux 2023 and Windows Server 2022, with optional ALB and
AWS Backup tagging.

## Usage

```hcl
module "workload_asg" {
  source = "./workload-asg"

  name        = "myapp-dev"
  environment = "dev"
  vpc_id      = "vpc-0123456789abcdef0"
  subnet_ids  = ["subnet-aaa", "subnet-bbb"]

  os         = "amazon-linux"
  create_alb = true
}
```

See [`examples/nonprod/main.tf`](examples/nonprod/main.tf) and
[`examples/prod/main.tf`](examples/prod/main.tf) for full examples.

## Accessing instances (no inbound ports required)

SSM Session Manager is configured via the IAM instance profile.

**Shell / PowerShell**
```bash
aws ssm start-session --target i-<instance-id>
```

**RDP tunnel (Windows)**
```bash
aws ssm start-session \
  --document-name AWS-StartPortForwardingSession \
  --parameters portNumber=3389,localPortNumber=13389
# then RDP to localhost:13389
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | string | required | Name prefix for all resources |
| `environment` | string | required | `dev`, `test`, `preprod`, or `prod` |
| `vpc_id` | string | required | Existing VPC ID |
| `subnet_ids` | list(string) | required | ≥2 subnet IDs for the ASG |
| `os` | string | `"amazon-linux"` | `"amazon-linux"` or `"windows"` |
| `instance_type` | string | `null` | Overrides environment default |
| `min_size` | number | `1` | |
| `max_size` | number | `4` | |
| `desired_capacity` | number | `null` | Defaults to `min_size` |
| `allowed_ingress_cidrs` | list(string) | `["10.0.0.0/8"]` | Port 80 ingress when ALB is off |
| `create_alb` | bool | `false` | Create ALB, target group, and listener |
| `alb_internal` | bool | `false` | Internal vs internet-facing ALB |
| `alb_subnet_ids` | list(string) | `[]` | ALB subnets; falls back to `subnet_ids` |
| `alb_ingress_cidrs` | list(string) | `["0.0.0.0/0"]` | CIDRs allowed to reach ALB port 80 |
| `backup_enabled` | bool | `true` | Add AWS Backup selection tags |
| `backup_retention_days` | number | `7` | Stored as a tag for Backup plan rules |
| `root_volume_size_gb` | number | `30` | Root EBS volume size (GiB) |
| `create_data_volume` | bool | `true` | Attach a second EBS volume |
| `data_volume_size_gb` | number | `50` | Data EBS volume size (GiB) |
| `tags` | map(string) | `{}` | Additional tags merged onto all resources |

## Outputs

| Name | Description |
|---|---|
| `asg_name` | Auto Scaling Group name |
| `asg_arn` | Auto Scaling Group ARN |
| `launch_template_id` | Launch Template ID |
| `launch_template_latest_version` | Latest Launch Template version |
| `instance_sg_id` | Instance security group ID |
| `alb_sg_id` | ALB security group ID (empty when `create_alb = false`) |
| `alb_arn` | ALB ARN (empty when `create_alb = false`) |
| `alb_dns_name` | ALB DNS name — paste into browser to reach the demo page |
| `target_group_arn` | Target group ARN (empty when `create_alb = false`) |
| `iam_instance_profile_name` | IAM instance profile name |
| `iam_role_arn` | IAM role ARN |
| `ami_id` | Resolved AMI ID |
| `effective_instance_type` | Resolved instance type |
