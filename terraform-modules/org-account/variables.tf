variable "account_name" {
  description = "Name of the AWS account"
  type        = string
}

variable "account_email" {
  description = "Email address for the AWS account root user"
  type        = string
}

variable "parent_id" {
  description = "Parent Organizational Unit (OU) ID or Root ID for the account"
  type        = string
}

variable "role_name" {
  description = "Name of the IAM role created in the new account for cross-account access"
  type        = string
  default     = "OrganizationAccountAccessRole"
}

variable "iam_user_access_to_billing" {
  description = "Allow IAM users to access billing information"
  type        = string
  default     = "ALLOW"

  validation {
    condition     = contains(["ALLOW", "DENY"], var.iam_user_access_to_billing)
    error_message = "Must be either ALLOW or DENY."
  }
}

variable "close_on_deletion" {
  description = "Close the account on deletion"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to the account (map format)"
  type        = map(string)
  default     = {}
}

variable "account_tags" {
  description = "Tags to apply to the account (array format)"
  type = list(object({
    key   = string
    value = string
  }))
  default = []
}
