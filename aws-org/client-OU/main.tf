terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_organizations_organization" "current" {}

locals {
  root_id = data.aws_organizations_organization.current.roots[0].id
}

# Top-level OUs
module "sandbox" {
  source    = "../terraform-modules/org-ou"
  name      = "sandbox"
  parent_id = local.root_id
}

module "core" {
  source    = "../terraform-modules/org-ou"
  name      = "core"
  parent_id = local.root_id
}

module "control_plane" {
  source    = "../terraform-modules/org-ou"
  name      = "control-plane"
  parent_id = local.root_id
}

module "infrastructure" {
  source    = "../terraform-modules/org-ou"
  name      = "infrastructure"
  parent_id = local.root_id
}

# Nested OUs under infrastructure
module "it_non_prod" {
  source    = "../terraform-modules/org-ou"
  name      = "it-non-prod"
  parent_id = module.infrastructure.id
}

module "it_prod" {
  source    = "../terraform-modules/org-ou"
  name      = "it-prod"
  parent_id = module.infrastructure.id
}

module "ot_non_prod" {
  source    = "../terraform-modules/org-ou"
  name      = "ot-non-prod"
  parent_id = module.infrastructure.id
}

module "ot_prod" {
  source    = "../terraform-modules/org-ou"
  name      = "ot-prod"
  parent_id = module.infrastructure.id
}

# resource "aws_organizations_account" "finops" {
#   name              = "finops"
#   email             = "finops@client.domain"
#   close_on_deletion = true
#   parent_id         = module.control_plane.ou.id
#   tags = {
#     service              = "billing"
#     owner                = "tbc"
#     environment          = "prod"
#     business-unit        = "TechOps"
#     system-domain        = "IT"
#     business-criticality = "t0"
#   }
# }
#
# resource "aws_organizations_account" "aft" {
#   name              = "vending"
#   email             = "aft@client.domain"
#   close_on_deletion = true
#   parent_id         = module.control_plane.ou.id
#   tags = {
#     service              = "aft"
#     owner                = "tbc"
#     environment          = "prod"
#     business-unit        = "TechOps"
#     system-domain        = "IT"
#     business-criticality = "t0"
#   }
# }
#
# resource "aws_organizations_account" "network" {
#   name              = "network"
#   email             = "network@client.domain"
#   close_on_deletion = true
#   parent_id         = module.core.ou.id
#   tags = {
#     service              = "hub-nw"
#     owner                = "tbc"
#     environment          = "prod"
#     business-unit        = "TechOps"
#     system-domain        = "IT"
#     business-criticality = "t0"
#   }
# }
#

