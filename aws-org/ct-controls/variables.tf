
# Optional: allow overriding OUs if needed
variable "ou_overrides" {
  type    = map(list(string))
  default = {}
}
