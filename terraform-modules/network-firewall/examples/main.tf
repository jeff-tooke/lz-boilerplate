################################################################################
# Example: Network Firewall with DR
# This example demonstrates deploying AWS Network Firewall with multi-region DR
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
# Variables
################################################################################

variable "dr_enabled" {
  description = "Enable DR region deployment"
  type        = bool
  default     = true
}

################################################################################
# Data Sources (assumes hub-vpc module has been deployed)
################################################################################

# In real usage, these would come from the hub-vpc module outputs
# Here we use placeholders for demonstration

locals {
  # These would typically be module.hub_vpc.firewall_subnet_ids_list
  primary_firewall_subnet_ids = ["subnet-primary-1", "subnet-primary-2", "subnet-primary-3"]
  dr_firewall_subnet_ids      = ["subnet-dr-1", "subnet-dr-2", "subnet-dr-3"]

  # These would typically be module.hub_vpc.vpc_id and module.hub_vpc.dr_vpc_id
  primary_vpc_id = "vpc-primary"
  dr_vpc_id      = "vpc-dr"

  # Home network CIDRs for firewall rules
  home_net_cidrs = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

################################################################################
# Network Firewall Module
################################################################################

module "network_firewall" {
  source = "../"

  name        = "prod-hub"
  environment = "production"

  # Primary region configuration
  vpc_id     = local.primary_vpc_id
  subnet_ids = local.primary_firewall_subnet_ids

  # Firewall policy configuration
  policy_stateful_rule_order       = "STRICT_ORDER"
  policy_stateless_default_actions = ["aws:forward_to_sfe"]
  policy_stateful_default_actions  = ["aws:drop_established", "aws:alert_established"]

  # Stateless rule groups
  stateless_rule_groups = [
    {
      name        = "drop-icmp"
      description = "Drop ICMP traffic from internet"
      priority    = 100
      capacity    = 100
      rules = [
        {
          priority = 1
          actions  = ["aws:drop"]
          match = {
            protocols         = [1] # ICMP
            source_cidrs      = ["0.0.0.0/0"]
            destination_cidrs = ["10.0.0.0/8"]
          }
        }
      ]
    }
  ]

  # Stateful rule groups using Suricata rules
  stateful_rule_groups = [
    {
      name        = "block-threats"
      description = "Block known threat signatures"
      priority    = 100
      capacity    = 1000
      rules       = <<-EOT
        # Block SSH brute force attempts
        drop ssh any any -> $HOME_NET 22 (msg:"Potential SSH brute force"; sid:1000001; rev:1;)

        # Alert on suspicious outbound DNS
        alert dns $HOME_NET any -> any 53 (msg:"DNS query to suspicious TLD"; dns.query; content:".xyz"; nocase; sid:1000002; rev:1;)

        # Allow established connections
        pass tcp $HOME_NET any <> any any (flow:established; sid:1000003; rev:1;)
      EOT
    }
  ]

  # Domain-based rule groups
  stateful_domain_rule_groups = [
    {
      name           = "allow-aws-services"
      description    = "Allow traffic to AWS service endpoints"
      priority       = 200
      capacity       = 500
      action         = "ALLOWLIST"
      protocols      = ["HTTP_HOST", "TLS_SNI"]
      home_net_cidrs = local.home_net_cidrs
      domain_list = [
        ".amazonaws.com",
        ".aws.amazon.com",
        ".amazontrust.com"
      ]
    },
    {
      name           = "block-malicious-domains"
      description    = "Block known malicious domains"
      priority       = 300
      capacity       = 500
      action         = "DENYLIST"
      protocols      = ["HTTP_HOST", "TLS_SNI"]
      home_net_cidrs = local.home_net_cidrs
      domain_list = [
        "malware.example.com",
        "phishing.example.com",
        ".badactor.com"
      ]
    }
  ]

  # Logging configuration
  logging_enabled    = true
  log_retention_days = 30

  # Protection settings (enable in production)
  delete_protection                 = false
  subnet_change_protection          = false
  firewall_policy_change_protection = false

  # DR configuration
  dr_enabled    = var.dr_enabled
  dr_region     = "eu-west-2"
  dr_vpc_id     = local.dr_vpc_id
  dr_subnet_ids = local.dr_firewall_subnet_ids

  tags = {
    Project = "core-network"
    Owner   = "platform-team"
  }
}

################################################################################
# Example Route Table Updates
# Shows how to route traffic through the firewall endpoints
################################################################################

# This is an example of how you would update route tables to send traffic
# through the firewall. In practice, you would add routes in your hub-vpc
# or core-network-hub module.

# resource "aws_route" "tgw_to_firewall" {
#   for_each = module.hub_vpc.tgw_attachment_route_table_ids
#
#   route_table_id         = each.value
#   destination_cidr_block = "0.0.0.0/0"
#   vpc_endpoint_id        = module.network_firewall.firewall_endpoint_ids[each.key]
# }

################################################################################
# Outputs
################################################################################

output "firewall" {
  description = "Primary firewall details"
  value = {
    id           = module.network_firewall.firewall_id
    arn          = module.network_firewall.firewall_arn
    name         = module.network_firewall.firewall_name
    endpoint_ids = module.network_firewall.firewall_endpoint_ids
  }
}

output "dr_firewall" {
  description = "DR firewall details"
  value = {
    id           = module.network_firewall.dr_firewall_id
    arn          = module.network_firewall.dr_firewall_arn
    name         = module.network_firewall.dr_firewall_name
    endpoint_ids = module.network_firewall.dr_firewall_endpoint_ids
  }
}

output "policy" {
  description = "Firewall policy details"
  value = {
    primary_arn = module.network_firewall.firewall_policy_arn
    dr_arn      = module.network_firewall.dr_firewall_policy_arn
  }
}

output "logging" {
  description = "Logging configuration"
  value = {
    primary_alert_log = module.network_firewall.alert_log_group_name
    primary_flow_log  = module.network_firewall.flow_log_group_name
    dr_alert_log      = module.network_firewall.dr_alert_log_group_name
    dr_flow_log       = module.network_firewall.dr_flow_log_group_name
  }
}

output "routing_example" {
  description = "Example of how to use firewall endpoints for routing"
  value       = <<-EOT

    ============================================================
    FIREWALL ROUTING CONFIGURATION
    ============================================================

    The firewall endpoint IDs should be used as the next-hop for
    routes in your TGW attachment and egress route tables.

    Primary Region Endpoints:
    ${jsonencode(module.network_firewall.firewall_endpoint_ids)}

    DR Region Endpoints:
    ${jsonencode(module.network_firewall.dr_firewall_endpoint_ids)}

    Example route configuration:

    resource "aws_route" "to_firewall" {
      route_table_id         = aws_route_table.tgw.id
      destination_cidr_block = "0.0.0.0/0"
      vpc_endpoint_id        = "<firewall-endpoint-id>"
    }

    ============================================================
  EOT
}
