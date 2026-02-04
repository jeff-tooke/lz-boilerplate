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

resource "aws_ssoadmin_permission_set_inline_policy" "read_only_deny_data_access" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.read_only.arn

  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ---- S3 ----
      {
        Sid    = "DenyS3ObjectAccess"
        Effect = "Deny"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::*/*"
      },

      # ---- Secrets Manager ----
      {
        Sid    = "DenySecretsValues"
        Effect = "Deny"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "*"
      },

      # ---- SSM Parameter Store ----
      {
        Sid    = "DenySSMParameterValues"
        Effect = "Deny"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ]
        Resource = "*"
      },

      # ---- RDS / DynamoDB data APIs ----
      {
        Sid    = "DenyDatabaseDataAccess"
        Effect = "Deny"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "rds-data:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_ssoadmin_managed_policy_attachment" "read_only" {
  instance_arn       = local.sso_instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  permission_set_arn = aws_ssoadmin_permission_set.read_only.arn
}

# Power User IAM Read-Only Permission Set
resource "aws_ssoadmin_permission_set" "power_user_iam_ro" {
  name             = var.power_user_iam_ro_permission_set_name
  description      = "Power User access with IAM Read-Only permissions"
  instance_arn     = local.sso_instance_arn
  session_duration = var.session_duration

  tags = merge(var.tags, {
    Name = var.power_user_iam_ro_permission_set_name
  })
}

resource "aws_ssoadmin_managed_policy_attachment" "power_user" {
  instance_arn       = local.sso_instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
  permission_set_arn = aws_ssoadmin_permission_set.power_user_iam_ro.arn
}

resource "aws_ssoadmin_managed_policy_attachment" "iam_ro" {
  instance_arn       = local.sso_instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
  permission_set_arn = aws_ssoadmin_permission_set.power_user_iam_ro.arn
}

