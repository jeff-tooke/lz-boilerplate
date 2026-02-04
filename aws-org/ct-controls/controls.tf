
resource "aws_controltower_control" "this" {
  for_each = {
    for binding in local.control_bindings :
    "${binding.ou}-${basename(binding.control)}" => binding
  }

  target_identifier  = local.ou_arns[each.value.ou]
  control_identifier = each.value.control
}
