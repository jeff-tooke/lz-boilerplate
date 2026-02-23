################################################################################
# Execution Role — Policy Attachment
#
# Attaches AdministratorAccess to the Terraform execution role created by
# global customisations. This is the default permission set.
#
# To grant least-privilege to a specific account instead:
#   1. Create a new customisation directory (e.g. aft-account-customizations/RestrictedAccess/)
#   2. Attach a scoped IAM policy rather than AdministratorAccess
#   3. Set account_customizations_name = "RestrictedAccess" in that account's request
################################################################################

resource "aws_iam_role_policy_attachment" "terraform_execution_admin" {
  role       = local.exec_role_name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
