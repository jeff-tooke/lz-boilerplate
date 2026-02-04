locals {
  # Common tags applied to all resources
  common_tags = merge(
    var.tags,
    {
      ManagedBy     = "terraform"
      Module        = "vpc-endpoints"
      ModuleVersion = local.module_version
    }
  )

  # Gateway endpoints - only S3 and DynamoDB support gateway type
  gateway_services = ["s3", "dynamodb"]

  ################################################################################
  # Primary Region Endpoint Classification
  ################################################################################

  # Extract the service name (last segment) from full service name
  # e.g., "com.amazonaws.ap-southeast-2.s3" -> "s3"
  endpoint_service_names = {
    for svc in var.endpoints : svc => element(split(".", svc), length(split(".", svc)) - 1)
  }

  # Separate endpoints by type based on extracted service name
  gateway_endpoints = [
    for svc in var.endpoints : svc
    if contains(local.gateway_services, lower(local.endpoint_service_names[svc]))
  ]

  interface_endpoints = [
    for svc in var.endpoints : svc
    if !contains(local.gateway_services, lower(local.endpoint_service_names[svc]))
  ]

  # Determine actual security group IDs to use
  security_group_ids = length(var.security_group_ids) > 0 ? var.security_group_ids : (
    var.create_default_security_group && length(local.interface_endpoints) > 0 ? [aws_security_group.endpoint[0].id] : []
  )

  ################################################################################
  # DR Region Endpoint Classification (only when DR is enabled)
  ################################################################################

  # Extract the service name from DR endpoint service names
  dr_endpoint_service_names = var.dr_enabled ? {
    for svc in var.dr_endpoints : svc => element(split(".", svc), length(split(".", svc)) - 1)
  } : {}

  # Separate DR endpoints by type
  dr_gateway_endpoints = var.dr_enabled ? [
    for svc in var.dr_endpoints : svc
    if contains(local.gateway_services, lower(local.dr_endpoint_service_names[svc]))
  ] : []

  dr_interface_endpoints = var.dr_enabled ? [
    for svc in var.dr_endpoints : svc
    if !contains(local.gateway_services, lower(local.dr_endpoint_service_names[svc]))
  ] : []

  # Determine actual DR security group IDs to use
  dr_security_group_ids = var.dr_enabled ? (
    length(var.dr_security_group_ids) > 0 ? var.dr_security_group_ids : (
      var.create_default_security_group && length(local.dr_interface_endpoints) > 0 ? [aws_security_group.dr_endpoint[0].id] : []
    )
  ) : []
}
