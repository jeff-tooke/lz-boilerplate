output "administrator_permission_set_arn" {
  description = "ARN of the Administrator permission set"
  value       = aws_ssoadmin_permission_set.administrator.arn
}

output "administrator_permission_set_name" {
  description = "Name of the Administrator permission set"
  value       = aws_ssoadmin_permission_set.administrator.name
}

output "read_only_permission_set_arn" {
  description = "ARN of the Read Only permission set"
  value       = aws_ssoadmin_permission_set.read_only.arn
}

output "read_only_permission_set_name" {
  description = "Name of the Read Only permission set"
  value       = aws_ssoadmin_permission_set.read_only.name
}

output "sso_instance_arn" {
  description = "ARN of the SSO instance"
  value       = local.sso_instance_arn
}
