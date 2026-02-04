variable "name" {
  description = "Name of the Organizational Unit"
  type        = string
}

variable "parent_id" {
  description = "Parent ID for the OU (Root ID or parent OU ID)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the OU (map format)"
  type        = map(string)
  default     = {}
}

variable "ou_tags" {
  description = "Tags to apply to the OU (array format)"
  type = list(object({
    key   = string
    value = string
  }))
  default = []
}
