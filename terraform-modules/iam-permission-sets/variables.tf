variable "administrator_permission_set_name" {
  description = "Name for the Administrator permission set"
  type        = string
  default     = "Administrator"
}

variable "read_only_permission_set_name" {
  description = "Name for the Read Only permission set"
  type        = string
  default     = "ReadOnly"
}

variable "session_duration" {
  description = "Session duration for the permission sets (ISO 8601 format)"
  type        = string
  default     = "PT8H"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
