################################################################################
# Primary Region Outputs
################################################################################

output "gateway_endpoints" {
  description = "Map of gateway endpoint IDs"
  value = {
    for k, v in aws_vpc_endpoint.gateway : k => {
      id             = v.id
      arn            = v.arn
      dns_entry      = v.dns_entry
      prefix_list_id = v.prefix_list_id
    }
  }
}

output "interface_endpoints" {
  description = "Map of interface endpoint IDs"
  value = {
    for k, v in aws_vpc_endpoint.interface : k => {
      id                    = v.id
      arn                   = v.arn
      dns_entry             = v.dns_entry
      network_interface_ids = v.network_interface_ids
    }
  }
}

output "all_endpoint_ids" {
  description = "List of all VPC endpoint IDs"
  value = concat(
    [for v in aws_vpc_endpoint.gateway : v.id],
    [for v in aws_vpc_endpoint.interface : v.id]
  )
}

output "security_group_id" {
  description = "ID of the default security group created for interface endpoints (if created)"
  value       = length(aws_security_group.endpoint) > 0 ? aws_security_group.endpoint[0].id : null
}

output "endpoint_dns_entries" {
  description = "Map of endpoint service names to their DNS entries"
  value = merge(
    { for k, v in aws_vpc_endpoint.gateway : k => v.dns_entry },
    { for k, v in aws_vpc_endpoint.interface : k => v.dns_entry }
  )
}

################################################################################
# DR Region Outputs
################################################################################

output "dr_gateway_endpoints" {
  description = "Map of DR gateway endpoint IDs (empty if DR not enabled)"
  value = var.dr_enabled ? {
    for k, v in aws_vpc_endpoint.dr_gateway : k => {
      id             = v.id
      arn            = v.arn
      dns_entry      = v.dns_entry
      prefix_list_id = v.prefix_list_id
    }
  } : {}
}

output "dr_interface_endpoints" {
  description = "Map of DR interface endpoint IDs (empty if DR not enabled)"
  value = var.dr_enabled ? {
    for k, v in aws_vpc_endpoint.dr_interface : k => {
      id                    = v.id
      arn                   = v.arn
      dns_entry             = v.dns_entry
      network_interface_ids = v.network_interface_ids
    }
  } : {}
}

output "dr_all_endpoint_ids" {
  description = "List of all DR VPC endpoint IDs (empty if DR not enabled)"
  value = var.dr_enabled ? concat(
    [for v in aws_vpc_endpoint.dr_gateway : v.id],
    [for v in aws_vpc_endpoint.dr_interface : v.id]
  ) : []
}

output "dr_security_group_id" {
  description = "ID of the default security group created for DR interface endpoints (null if not created)"
  value       = var.dr_enabled && length(aws_security_group.dr_endpoint) > 0 ? aws_security_group.dr_endpoint[0].id : null
}

output "dr_endpoint_dns_entries" {
  description = "Map of DR endpoint service names to their DNS entries (empty if DR not enabled)"
  value = var.dr_enabled ? merge(
    { for k, v in aws_vpc_endpoint.dr_gateway : k => v.dns_entry },
    { for k, v in aws_vpc_endpoint.dr_interface : k => v.dns_entry }
  ) : {}
}
