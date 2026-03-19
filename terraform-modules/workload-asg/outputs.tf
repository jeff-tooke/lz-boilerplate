output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.this.arn
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.this.id
}

output "launch_template_latest_version" {
  description = "Latest version number of the Launch Template"
  value       = aws_launch_template.this.latest_version
}

output "instance_sg_id" {
  description = "ID of the instance security group"
  value       = aws_security_group.instances.id
}

output "alb_sg_id" {
  description = "ID of the ALB security group (empty string when create_alb is false)"
  value       = var.create_alb ? aws_security_group.alb[0].id : ""
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer (empty string when create_alb is false)"
  value       = var.create_alb ? aws_lb.this[0].arn : ""
}

output "alb_dns_name" {
  description = "DNS name of the ALB — paste into a browser to reach the workload (empty string when create_alb is false)"
  value       = var.create_alb ? aws_lb.this[0].dns_name : ""
}

output "target_group_arn" {
  description = "ARN of the ALB target group (empty string when create_alb is false)"
  value       = var.create_alb ? aws_lb_target_group.this[0].arn : ""
}

output "iam_instance_profile_name" {
  description = "Name of the IAM instance profile attached to ASG instances"
  value       = aws_iam_instance_profile.instances.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role attached to ASG instances"
  value       = aws_iam_role.instances.arn
}

output "ami_id" {
  description = "AMI ID resolved for the selected OS"
  value       = local.ami_id
}

output "effective_instance_type" {
  description = "Resolved EC2 instance type (after applying environment default)"
  value       = local.effective_instance_type
}
