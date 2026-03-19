################################################################################
# Example: Non-production workload (dev/test)
# - Amazon Linux 2023
# - t3.micro (environment default)
# - Internet-facing ALB
# - Backup enabled, 7-day retention
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
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0123456789abcdef0", "subnet-0fedcba9876543210"]
}

################################################################################
# workload-asg Module
################################################################################

module "workload_asg" {
  source = "../../"

  name        = "myapp-nonprod"
  environment = "dev"
  vpc_id      = local.vpc_id
  subnet_ids  = local.subnet_ids

  os = "amazon-linux"
  # instance_type omitted — uses t3.micro (dev default)

  min_size         = 1
  max_size         = 4
  desired_capacity = 2

  create_alb        = true
  alb_internal      = false
  alb_subnet_ids    = local.subnet_ids
  alb_ingress_cidrs = ["0.0.0.0/0"]

  backup_enabled        = true
  backup_retention_days = 7

  root_volume_size_gb = 30
  create_data_volume  = true
  data_volume_size_gb = 50

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
  description = "Paste this URL into a browser to reach the demo homepage"
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
