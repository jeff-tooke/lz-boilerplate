################################################################################
# IT Production Workload Accounts
# Add one module block per account vended into the it-prod OU.
# Production accounts default to business_criticality = "t1" to enable
# backup DR replication to eu-west-1.
# IT resources use the "st-" resource prefix.
################################################################################

# Example: replace with real account details
# module "it_prod_example" {
#   source               = "../modules/account-request"
#   svc_name             = "example"
#   account_email        = "aws+st-example-prod@example.com"
#   account_description  = "IT example workload (production)"
#   ou_name              = "Root/infrastructure/it-prod"
#   environment          = "prod"
#   system_domain        = "it"
#   business_criticality = "t1"
#   service_name         = "Example Service"
# }
