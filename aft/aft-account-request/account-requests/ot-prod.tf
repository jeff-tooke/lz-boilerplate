################################################################################
# OT Production Workload Accounts
# Add one module block per account vended into the ot-prod OU.
# Production accounts default to business_criticality = "t1" to enable
# backup DR replication to eu-west-1.
# OT resources use the "ot-" resource prefix for strong domain isolation.
# OT accounts MUST NOT share OUs or resource prefixes with IT accounts.
################################################################################

# Example: replace with real account details
# module "ot_prod_example" {
#   source               = "../modules/account-request"
#   svc_name             = "scada"
#   account_email        = "aws+ot-scada-prod@example.com"
#   account_description  = "OT SCADA workload (production)"
#   ou_name              = "Root/infrastructure/ot-prod"
#   environment          = "prod"
#   system_domain        = "ot"
#   business_criticality = "t1"
#   service_name         = "OT SCADA Service"
# }
