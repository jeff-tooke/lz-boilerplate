################################################################################
# General Configuration
################################################################################

variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = null
}

variable "secondary_region" {
  description = "Secondary AWS region for DR deployment (required if dr_enabled is true)"
  type        = string
  default     = ""
}

variable "name" {
  description = "Name prefix for firewall resources"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., prod, nonprod)"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

################################################################################
# Primary Region Configuration
################################################################################

variable "vpc_id" {
  description = "VPC ID where the firewall will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for firewall endpoints (one per AZ)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "At least one subnet ID must be provided."
  }
}

################################################################################
# Firewall Policy Configuration
################################################################################

variable "firewall_policy_arn" {
  description = "ARN of an existing firewall policy. If not provided, a new policy will be created."
  type        = string
  default     = ""
}

variable "policy_stateless_default_actions" {
  description = "Default actions for stateless traffic (aws:pass, aws:drop, aws:forward_to_sfe)"
  type        = list(string)
  default     = ["aws:forward_to_sfe"]
}

variable "policy_stateless_fragment_default_actions" {
  description = "Default actions for stateless fragmented traffic"
  type        = list(string)
  default     = ["aws:forward_to_sfe"]
}


variable "policy_stateful_rule_order" {
  description = "Rule order for stateful evaluation: STRICT_ORDER or DEFAULT_ACTION_ORDER"
  type        = string
  default     = "STRICT_ORDER"

  validation {
    condition     = contains(["STRICT_ORDER", "DEFAULT_ACTION_ORDER"], var.policy_stateful_rule_order)
    error_message = "Rule order must be STRICT_ORDER or DEFAULT_ACTION_ORDER."
  }
}

################################################################################
# Stateless Rule Groups
################################################################################

variable "stateless_rule_groups" {
  description = "List of stateless rule group configurations"
  type = list(object({
    name        = string
    description = string
    priority    = number
    capacity    = number
    rules = list(object({
      priority = number
      actions  = list(string)
      match = object({
        protocols         = list(number)
        source_cidrs      = list(string)
        destination_cidrs = list(string)
        source_ports = optional(list(object({
          from = number
          to   = number
        })), [])
        destination_ports = optional(list(object({
          from = number
          to   = number
        })), [])
      })
    }))
  }))
  default = []
}

################################################################################
# Stateful Rule Groups
################################################################################

variable "stateful_rule_groups" {
  description = "List of stateful rule group configurations using Suricata-compatible rules"
  type = list(object({
    name        = string
    description = string
    priority    = optional(number)
    capacity    = number
    rules       = string # Suricata-compatible rule string
  }))
  default = []
}

variable "stateful_domain_rule_groups" {
  description = "List of domain-based stateful rule group configurations"
  type = list(object({
    name           = string
    description    = string
    priority       = optional(number)
    capacity       = number
    domain_list    = list(string)
    action         = string # ALLOWLIST or DENYLIST
    protocols      = optional(list(string), ["HTTP_HOST", "TLS_SNI"])
    home_net_cidrs = optional(list(string), [])
  }))
  default = []
}

################################################################################
# Logging Configuration
################################################################################

variable "logging_enabled" {
  description = "Enable firewall logging"
  type        = bool
  default     = true
}

variable "alert_log_destination_type" {
  description = "Destination type for alert logs: CloudWatchLogs, S3, or KinesisDataFirehose"
  type        = string
  default     = "CloudWatchLogs"

  validation {
    condition     = contains(["CloudWatchLogs", "S3", "KinesisDataFirehose"], var.alert_log_destination_type)
    error_message = "Log destination type must be CloudWatchLogs, S3, or KinesisDataFirehose."
  }
}

variable "flow_log_destination_type" {
  description = "Destination type for flow logs: CloudWatchLogs, S3, or KinesisDataFirehose"
  type        = string
  default     = "CloudWatchLogs"

  validation {
    condition     = contains(["CloudWatchLogs", "S3", "KinesisDataFirehose"], var.flow_log_destination_type)
    error_message = "Log destination type must be CloudWatchLogs, S3, or KinesisDataFirehose."
  }
}

variable "alert_log_destination" {
  description = "Destination for alert logs (CloudWatch log group name, S3 bucket ARN, or Firehose ARN)"
  type        = string
  default     = ""
}

variable "flow_log_destination" {
  description = "Destination for flow logs (CloudWatch log group name, S3 bucket ARN, or Firehose ARN)"
  type        = string
  default     = ""
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days (only used if creating log groups)"
  type        = number
  default     = 30
}

################################################################################
# Encryption Configuration
################################################################################

variable "encryption_key_arn" {
  description = "KMS key ARN for encrypting firewall data. If not provided, AWS managed key is used."
  type        = string
  default     = ""
}

################################################################################
# Advanced Configuration
################################################################################

variable "delete_protection" {
  description = "Enable deletion protection on the firewall"
  type        = bool
  default     = false
}

variable "subnet_change_protection" {
  description = "Enable subnet change protection on the firewall"
  type        = bool
  default     = false
}

variable "firewall_policy_change_protection" {
  description = "Enable firewall policy change protection"
  type        = bool
  default     = false
}

################################################################################
# DR Region Configuration
################################################################################

variable "dr_enabled" {
  description = "Feature flag to enable DR region deployment"
  type        = bool
  default     = false
}


variable "dr_vpc_id" {
  description = "DR VPC ID where the firewall will be deployed (required if dr_enabled is true)"
  type        = string
  default     = ""
}

variable "dr_subnet_ids" {
  description = "List of DR subnet IDs for firewall endpoints (required if dr_enabled is true)"
  type        = list(string)
  default     = []
}

variable "dr_encryption_key_arn" {
  description = "KMS key ARN for encrypting DR firewall data"
  type        = string
  default     = ""
}
