terraform {
  required_version = "1.14.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.32.1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

locals {
  module_version = "1.0.0"
}
