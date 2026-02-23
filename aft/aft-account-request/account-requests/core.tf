################################################################################
# Core OU Accounts
# Add one module block per account vended into the core OU.
#
# Shared-services accounts are part of the
# IT system domain — system_domain = "it". Resources created in these accounts
# use the "st-" prefix. Core accounts are considered high-critical but will not
# store large quantities of data as such DR is managed primarily by IaC.
################################################################################

# Example: replace with real account details
# module "core_shared_services" {
#   source               = "../modules/account-request"
#   svc_name             = "shared-service"
#   account_email        = "aws+st-shared-services-prod@example.com"
#   account_description  = "Core shared-services account"
#   ou_name              = "Root/core"
#   environment          = "prod"
#   system_domain        = "it"
#   business_criticality = "t0"
#   service_name         = "Shared Service"
# }
