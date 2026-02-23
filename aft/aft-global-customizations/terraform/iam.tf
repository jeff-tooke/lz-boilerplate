################################################################################
# Terraform Execution Role
#
# Consistent role name across all accounts to simplify role-chaining from
# Azure DevOps federation roles in the management account.
#
# Trust: federation roles listed in /aft/config/federation-role-arns SSM param.
# Policy: NONE attached here — delegated to the Standard account customisation.
#         This separation allows future customisations to grant least-privilege
#         without changing the global baseline.
#
# sts:ExternalId is set to the account ID as a defence-in-depth measure for
# role-chaining. The ADO pipeline must pass ExternalId = <target-account-id>
# in the AssumeRole call. Remove the Condition block if your ADO setup does
# not support ExternalId.
################################################################################

resource "aws_iam_role" "terraform_execution" {
  name        = local.exec_role_name
  description = "Role assumed by Azure DevOps pipelines to run Terraform in this account"
  path        = "/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowFederationRoles"
        Effect = "Allow"
        Principal = {
          AWS = local.federation_role_arns
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = local.account_id
          }
        }
      }
    ]
  })

  tags = merge(
    local.common_tags,
    {
      Name = local.exec_role_name
    }
  )
}
