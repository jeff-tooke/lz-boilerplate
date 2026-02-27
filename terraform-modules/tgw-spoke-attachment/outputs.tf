################################################################################
# Module Version
################################################################################

output "module_version" {
  description = "Version of the tgw-spoke-attachment module"
  value       = local.module_version
}

################################################################################
# Association and Propagation Outputs
################################################################################

output "env_route_table_association_id" {
  description = "ID of the TGW route table association between this spoke and its environment route table"
  value       = aws_ec2_transit_gateway_route_table_association.spoke_env.id
}

output "inspection_propagation_id" {
  description = "ID of the TGW route table propagation from this spoke into the inspection route table"
  value       = aws_ec2_transit_gateway_route_table_propagation.spoke_to_inspection.id
}

output "shared_services_propagation_id" {
  description = "ID of the TGW route table propagation from this spoke into the shared services route table (null if shared services route table not provided)"
  value       = local.create_shared_services_propagation ? aws_ec2_transit_gateway_route_table_propagation.spoke_to_shared_services[0].id : null
}
