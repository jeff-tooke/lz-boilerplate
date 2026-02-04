data "aws_ssoadmin_instances" "this" {}

locals {
  sso_instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
}

# Administrator Permission Set
resource "aws_ssoadmin_permission_set" "administrator" {
  name             = var.administrator_permission_set_name
  description      = "Administrator access with full permissions"
  instance_arn     = local.sso_instance_arn
  session_duration = var.session_duration

  tags = merge(var.tags, {
    Name = var.administrator_permission_set_name
  })
}

resource "aws_ssoadmin_managed_policy_attachment" "administrator" {
  instance_arn       = local.sso_instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.administrator.arn
}

# Read Only Permission Set
resource "aws_ssoadmin_permission_set" "read_only" {
  name             = var.read_only_permission_set_name
  description      = "Read-only access to view resources"
  instance_arn     = local.sso_instance_arn
  session_duration = var.session_duration

  tags = merge(var.tags, {
    Name = var.read_only_permission_set_name
  })
}

resource "aws_ssoadmin_managed_policy_attachment" "read_only" {
  instance_arn       = local.sso_instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  permission_set_arn = aws_ssoadmin_permission_set.read_only.arn
}
