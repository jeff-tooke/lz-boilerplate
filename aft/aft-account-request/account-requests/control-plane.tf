################################################################################
# Control-Plane Accounts
# Add one module block per account vended into the control-plane OU.
#
# Control-plane accounts host platform infrastructure (AFT management,
# They are always owned by the IT system domain — system_domain = "it". Resources 
# created in these accounts use the "st-" prefix.
#  
# Account name convention: it-<service> (system_domain forms the first segment)
################################################################################

# Example: Cost management account
# module "control_plane_finops" {
#   source               = "../modules/account-request"
#   svc_name             = "finops"
#   account_email        = "aws+st-finops-prod@example.com"
#   account_description  = "Billing management account — orc"
#   ou_name              = "Root/control-plane"
#   environment          = "prod"
#   system_domain        = "it"
#   business_criticality = "t0"
#   service_name         = "Cost Management"
# }
