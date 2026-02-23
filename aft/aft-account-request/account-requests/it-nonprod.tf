################################################################################
# IT Non-Production Workload Accounts
# Add one module block per account vended into the it-nonprod OU.
# Valid environments for this OU: dev, test, pre-prod
# IT resources use the "st-" resource prefix.
################################################################################

# Example — dev environment: replace with real account details
# module "it_dev_example" {
#   source               = "../modules/account-request"
#   svc_name             = "example"
#   account_email        = "aws+st-example-dev@example.com"
#   account_description  = "IT example workload (dev)"
#   ou_name              = "Root/infrastructure/it-nonprod"
#   environment          = "dev"
#   system_domain        = "it"
#   business_criticality = "t3"
#   service_name         = "Example Service"
# }

# Example — test environment
# module "it_test_example" {
#   source               = "../modules/account-request"
#   svc_name             = "example"
#   account_email        = "aws+st-example-test@example.com"
#   account_description  = "IT example workload (test)"
#   ou_name              = "Root/infrastructure/it-nonprod"
#   environment          = "test"
#   system_domain        = "it"
#   business_criticality = "t3"
#   service_name         = "Example Service"
# }

# Example — pre-prod environment
# module "it_preprod_example" {
#   source               = "../modules/account-request"
#   svc_name             = "example"
#   account_email        = "aws+st-example-pre-prod@example.com"
#   account_description  = "IT example workload (pre-prod)"
#   ou_name              = "Root/infrastructure/it-nonprod"
#   environment          = "pre-prod"
#   system_domain        = "it"
#   business_criticality = "t3"
#   service_name         = "Example Service"
# }
