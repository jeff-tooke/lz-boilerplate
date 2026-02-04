
# Example of discovering OU IDs dynamically
# Only needed if you don't hardcode ARNs

data "aws_organizations_organizational_units" "root_ou" {
  parent_id = "r-examplerootid"
}

# Map OU names to ARNs dynamically
locals {
  ou_arns_dynamic = {
    for ou in data.aws_organizations_organizational_units.root_ou.children :
    ou.name => ou.arn
  }
}
