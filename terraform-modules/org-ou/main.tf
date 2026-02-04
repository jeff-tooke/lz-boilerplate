resource "aws_organizations_organizational_unit" "this" {
  name      = var.name
  parent_id = var.parent_id

  tags = merge(
    var.tags,
    local.ou_tags_map,
    { Name = var.name }
  )
}

locals {
  ou_tags_map = { for tag in var.ou_tags : tag.key => tag.value }
}
