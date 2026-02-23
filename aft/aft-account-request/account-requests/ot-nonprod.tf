################################################################################
# OT Non-Production Workload Accounts
# Add one module block per account vended into the ot-nonprod OU.
# Valid environments for this OU: dev, test, pre-prod
# OT resources use the "ot-" resource prefix for strong domain isolation.
# OT accounts MUST NOT share OUs or resource prefixes with IT accounts.
################################################################################

# Example — dev environment: replace with real account details
# module "ot_dev_example" {
#   source               = "../modules/account-request"
#   svc_name             = "scada"
#   account_email        = "aws+ot-scada-dev@example.com"
#   account_description  = "OT SCADA workload (dev)"
#   ou_name              = "Root/infrastructure/ot-nonprod"
#   environment          = "dev"
#   system_domain        = "ot"
#   business_criticality = "t3"
#   service_name         = "OT SCADA Service"
# }

# Example — test environment
# module "ot_test_example" {
#   source               = "../modules/account-request"
#   svc_name             = "scada"
#   account_email        = "aws+ot-scada-test@example.com"
#   account_description  = "OT SCADA workload (test)"
#   ou_name              = "Root/infrastructure/ot-nonprod"
#   environment          = "test"
#   system_domain        = "ot"
#   business_criticality = "t3"
#   service_name         = "OT SCADA Service"
# }

# Example — pre-prod environment
# module "ot_preprod_example" {
#   source               = "../modules/account-request"
#   svc_name             = "scada"
#   account_email        = "aws+ot-scada-pre-prod@example.com"
#   account_description  = "OT SCADA workload (pre-prod)"
#   ou_name              = "Root/infrastructure/ot-nonprod"
#   environment          = "pre-prod"
#   system_domain        = "ot"
#   business_criticality = "t3"
#   service_name         = "OT SCADA Service"
# }
