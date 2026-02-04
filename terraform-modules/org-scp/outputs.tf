output "scp_ids" {
  description = "Map of SCP names to their IDs"
  value       = { for key, scp in aws_organizations_policy.this : key => scp.id }
}

output "scp_arns" {
  description = "Map of SCP names to their ARNs"
  value       = { for key, scp in aws_organizations_policy.this : key => scp.arn }
}

output "enabled_scps" {
  description = "List of enabled SCP keys"
  value       = keys(local.enabled_scps)
}

output "attachment_count" {
  description = "Number of SCP attachments created"
  value       = length(aws_organizations_policy_attachment.this)
}
