output "sandbox_ou_id" {
  description = "ID of the sandbox OU"
  value       = module.sandbox.id
}

output "core_ou_id" {
  description = "ID of the core OU"
  value       = module.core.id
}

output "control_plane_ou_id" {
  description = "ID of the control-plane OU"
  value       = module.control_plane.id
}

output "infrastructure_ou_id" {
  description = "ID of the infrastructure OU"
  value       = module.infrastructure.id
}

output "it_non_prod_ou_id" {
  description = "ID of the it-non-prod OU"
  value       = module.it_non_prod.id
}

output "it_prod_ou_id" {
  description = "ID of the it-prod OU"
  value       = module.it_prod.id
}

output "ot_non_prod_ou_id" {
  description = "ID of the ot-non-prod OU"
  value       = module.ot_non_prod.id
}

output "ot_prod_ou_id" {
  description = "ID of the ot-prod OU"
  value       = module.ot_prod.id
}
