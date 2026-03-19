################################################################################
# Example: Production workload
# - Windows Server 2022
# - t3.small (environment default)
# - Internal ALB (no public internet exposure)
# - Backup enabled, 30-day retention
#
# Access methods (no inbound SG rules required):
#   Shell:  aws ssm start-session --target i-<instance-id>
#   RDP:    aws ssm start-session \
#             --document-name AWS-StartPortForwardingSession \
#             --parameters portNumber=3389,localPortNumber=13389
#           then RDP to localhost:13389
################################################################################

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

################################################################################
# Replace these locals with real IDs from your spoke-vpc module outputs
################################################################################

locals {
  vpc_id         = "vpc-0123456789abcdef1"
  subnet_ids     = ["subnet-0123456789abcdef1", "subnet-0fedcba9876543211"]
  alb_subnet_ids = ["subnet-0123456789abcdef1", "subnet-0fedcba9876543211"]
}

################################################################################
# workload-asg Module
################################################################################

module "workload_asg" {
  source = "../../"

  name        = "myapp-prod"
  environment = "prod"
  vpc_id      = local.vpc_id
  subnet_ids  = local.subnet_ids

  os = "windows"
  # instance_type omitted — uses t3.small (prod default)

  min_size         = 2
  max_size         = 8
  desired_capacity = 2

  create_alb        = true
  alb_internal      = true
  alb_subnet_ids    = local.alb_subnet_ids
  alb_ingress_cidrs = ["10.0.0.0/8"]

  backup_enabled        = true
  backup_retention_days = 30

  root_volume_size_gb = 50
  create_data_volume  = true
  data_volume_size_gb = 100

  tags = {
    Project     = "demo"
    CostCentre  = "engineering"
  }
}

################################################################################
# Outputs
################################################################################

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = module.workload_asg.asg_name
}

output "alb_dns_name" {
  description = "ALB DNS name (internal — reachable from within the VPC or via VPN)"
  value       = "http://${module.workload_asg.alb_dns_name}"
}

output "effective_instance_type" {
  description = "Resolved instance type"
  value       = module.workload_asg.effective_instance_type
}

output "ami_id" {
  description = "AMI ID used for this deployment"
  value       = module.workload_asg.ami_id
}

output "iam_role_arn" {
  description = "IAM role ARN for the instance profile (SSM access)"
  value       = module.workload_asg.iam_role_arn
}
