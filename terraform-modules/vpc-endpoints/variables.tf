variable "primary_region" {
  description = "Primary AWS region"
  type        = string
  default     = null
}

variable "secondary_region" {
  description = "Secondary AWS region for DR deployment (required if dr_enabled is true)"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "The ID of the VPC to create endpoints in"
  type        = string
}

variable "endpoints" {
  description = "List of full AWS VPC endpoint service names (e.g., 'com.amazonaws.ap-southeast-2.s3', 'com.amazonaws.ap-southeast-2.ssm')"
  type        = list(string)
  default     = []
}

variable "subnet_ids" {
  description = "List of subnet IDs for interface endpoints"
  type        = list(string)
  default     = []
}

variable "route_table_ids" {
  description = "List of route table IDs for gateway endpoints (S3, DynamoDB)"
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to interface endpoints. If empty, a default security group will be created."
  type        = list(string)
  default     = []
}

variable "create_default_security_group" {
  description = "Whether to create a default security group for interface endpoints when security_group_ids is empty"
  type        = bool
  default     = true
}

variable "private_dns_enabled" {
  description = "Whether to enable private DNS for interface endpoints"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "endpoint_tags" {
  description = "Additional tags to apply to specific endpoints. Map of service name to tags."
  type        = map(map(string))
  default     = {}
}

################################################################################
# DR Region Variables
################################################################################

variable "dr_enabled" {
  description = "Feature flag to enable DR region deployment"
  type        = bool
  default     = false
}


variable "dr_vpc_id" {
  description = "The ID of the DR VPC to create endpoints in (required if dr_enabled is true)"
  type        = string
  default     = ""
}

variable "dr_endpoints" {
  description = "List of full AWS VPC endpoint service names for DR region (e.g., 'com.amazonaws.eu-west-2.s3'). Must use DR region in service names."
  type        = list(string)
  default     = []
}

variable "dr_subnet_ids" {
  description = "List of subnet IDs for DR interface endpoints (required if dr_enabled is true)"
  type        = list(string)
  default     = []
}

variable "dr_route_table_ids" {
  description = "List of route table IDs for DR gateway endpoints (required if dr_enabled is true)"
  type        = list(string)
  default     = []
}

variable "dr_security_group_ids" {
  description = "List of security group IDs to attach to DR interface endpoints. If empty, a default security group will be created."
  type        = list(string)
  default     = []
}

################################################################################
# Endpoint Policy Variables
################################################################################

variable "interface_endpoint_policy" {
  description = "IAM policy document (JSON) to attach to all interface endpoints. When null, the AWS-managed default (allow all) applies."
  type        = string
  default     = null
}

variable "gateway_endpoint_policy" {
  description = "IAM policy document (JSON) to attach to all gateway endpoints (S3, DynamoDB). When null, the AWS-managed default (allow all) applies."
  type        = string
  default     = null
}

variable "dr_interface_endpoint_policy" {
  description = "IAM policy document (JSON) to attach to all DR region interface endpoints. When null, the AWS-managed default (allow all) applies."
  type        = string
  default     = null
}

variable "dr_gateway_endpoint_policy" {
  description = "IAM policy document (JSON) to attach to all DR region gateway endpoints (S3, DynamoDB). When null, the AWS-managed default (allow all) applies."
  type        = string
  default     = null
}

################################################################################
# Spoke Supernet Security Group Variables
################################################################################

variable "spoke_cidr_supernet" {
  description = "CIDR supernet covering all spoke VPCs (e.g. 10.0.0.0/8). When provided, the default endpoint security group adds an HTTPS ingress rule for this range in addition to the hub VPC CIDR. Required when Network Firewall preserves source IPs (no SNAT) so spoke traffic reaches endpoint ENIs with spoke-origin addresses."
  type        = string
  default     = ""
}

variable "dr_spoke_cidr_supernet" {
  description = "CIDR supernet covering all DR-region spoke VPCs. When provided, the DR default endpoint security group adds an HTTPS ingress rule for this range."
  type        = string
  default     = ""
}
