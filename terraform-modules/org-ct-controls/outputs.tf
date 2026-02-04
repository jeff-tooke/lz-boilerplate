output "enabled_control_arns" {
  description = "List of enabled control ARNs"
  value       = [for c in aws_controltower_control.this : c.control_identifier]
}

output "control_count" {
  description = "Number of controls enabled"
  value       = length(aws_controltower_control.this)
}

output "control_ids" {
  description = "Map of control keys to their resource IDs"
  value       = { for key, control in aws_controltower_control.this : key => control.id }
}

output "available_controls" {
  description = "List of available control keys in the catalog"
  value       = keys(local.control_catalog)
}
