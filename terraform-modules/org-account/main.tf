locals {
  # Convert array-style tags to map format
  account_tags_map = { for tag in var.account_tags : tag.key => tag.value }

  # Merge all tags together
  all_tags = merge(
    var.tags,
    local.account_tags_map,
    { Name = var.account_name }
  )
}

resource "aws_organizations_account" "this" {
  name                       = var.account_name
  email                      = var.account_email
  parent_id                  = var.parent_id
  role_name                  = var.role_name
  iam_user_access_to_billing = var.iam_user_access_to_billing
  close_on_deletion          = var.close_on_deletion

  tags = local.all_tags

  lifecycle {
    ignore_changes = [role_name]
  }
}
