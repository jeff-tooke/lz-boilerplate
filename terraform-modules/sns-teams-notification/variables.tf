variable "name" {
  description = "Name prefix for all resources"
  type        = string
}

variable "teams_webhook_url" {
  description = "Microsoft Teams incoming webhook URL"
  type        = string
  sensitive   = true
}

variable "rate_limit_per_second" {
  description = "Maximum number of invocations per second for the API destination"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "kms_key_arn" {
  description = "KMS key ARN to encrypt SNS topic and SQS queue. If not provided, AWS managed keys will be used."
  type        = string
  default     = null
}
