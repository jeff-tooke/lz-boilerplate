variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "environment" {
  description = "Environment name; must be one of dev, test, preprod, prod"
  type        = string

  validation {
    condition     = contains(["dev", "test", "preprod", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, preprod, prod"
  }
}

variable "vpc_id" {
  description = "ID of the existing VPC to deploy into"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ASG; must contain at least 2 subnets (one per AZ)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "subnet_ids must contain at least 2 subnet IDs"
  }
}

variable "os" {
  description = "Operating system for instances: 'amazon-linux' or 'windows'"
  type        = string
  default     = "amazon-linux"

  validation {
    condition     = contains(["amazon-linux", "windows"], var.os)
    error_message = "os must be either 'amazon-linux' or 'windows'"
  }
}

variable "instance_type" {
  description = "EC2 instance type; null uses environment default (t3.micro for nonprod, t3.small for prod)"
  type        = string
  default     = null
}

variable "min_size" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 4
}

variable "desired_capacity" {
  description = "Desired number of instances; null defaults to min_size"
  type        = number
  default     = null
}

variable "allowed_ingress_cidrs" {
  description = "CIDR blocks allowed to reach port 80 on instances when create_alb is false"
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "create_alb" {
  description = "When true, creates an Application Load Balancer, target group, and listener"
  type        = bool
  default     = false
}

variable "alb_internal" {
  description = "When true, the ALB is internal (private); when false it is internet-facing"
  type        = bool
  default     = false
}

variable "alb_subnet_ids" {
  description = "Subnet IDs for the ALB; required when create_alb is true"
  type        = list(string)
  default     = []
}

variable "alb_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the ALB on port 80"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "backup_enabled" {
  description = "When true, adds AWS Backup selection tags to instances and volumes"
  type        = bool
  default     = true
}

variable "backup_retention_days" {
  description = "Backup retention period in days; stored as a tag for AWS Backup plan rules"
  type        = number
  default     = 7
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 30
}

variable "create_data_volume" {
  description = "When true, attaches a second EBS data volume (/dev/sdb); mounted at /data on Linux and D:\\ on Windows"
  type        = bool
  default     = true
}

variable "data_volume_size_gb" {
  description = "Data EBS volume size in GiB"
  type        = number
  default     = 50
}

variable "tags" {
  description = "Additional tags to merge onto all resources"
  type        = map(string)
  default     = {}
}
