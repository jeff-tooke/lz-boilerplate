output "id" {
  description = "The ID of the Organizational Unit"
  value       = aws_organizations_organizational_unit.this.id
}

output "arn" {
  description = "The ARN of the Organizational Unit"
  value       = aws_organizations_organizational_unit.this.arn
}

output "name" {
  description = "The name of the Organizational Unit"
  value       = aws_organizations_organizational_unit.this.name
}

output "parent_id" {
  description = "The parent ID of the Organizational Unit"
  value       = aws_organizations_organizational_unit.this.parent_id
}
