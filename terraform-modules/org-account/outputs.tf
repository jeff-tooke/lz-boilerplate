output "account_id" {
  description = "The AWS account ID"
  value       = aws_organizations_account.this.id
}

output "account_arn" {
  description = "The ARN of the AWS account"
  value       = aws_organizations_account.this.arn
}

output "account_name" {
  description = "The name of the AWS account"
  value       = aws_organizations_account.this.name
}

output "account_email" {
  description = "The email address of the AWS account"
  value       = aws_organizations_account.this.email
}

output "role_arn" {
  description = "ARN of the cross-account access role"
  value       = "arn:aws:iam::${aws_organizations_account.this.id}:role/${var.role_name}"
}
