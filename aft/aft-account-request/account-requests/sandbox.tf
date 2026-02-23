################################################################################
# Sandbox Accounts
# Add one module block per account vended into the sandbox OU.
# Sandbox accounts use low criticality — no DR backup replication.
# Sandbox accounts are always owned by the IT system domain (system_domain = "it")
# and use the "st-" resource prefix.
################################################################################

# Example: replace with real account details
# module "sandbox_example" {
#   source               = "../modules/account-request"
#   svc_name             = "sandbox"
#   account_email        = "aws+st-sandbox-sandbox@example.com"
#   account_description  = "Sandbox experimentation account"
#   ou_name              = "Root/sandbox"
#   environment          = "sandbox"
#   system_domain        = "it"
#   business_criticality = "t4"
#   service_name         = "Sandbox"
# }
