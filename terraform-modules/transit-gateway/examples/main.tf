################################################################################
# Example: Transit Gateway with RAM Sharing
################################################################################

# Basic Transit Gateway (single region, no sharing)
module "transit_gateway_basic" {
  source = "../"

  name        = "myorg-prod"
  environment = "prod"

  # Create a new Transit Gateway
  create_transit_gateway = true
  amazon_side_asn        = 64512

  # Attach to hub VPC
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]

  tags = {
    Project = "network-hub"
  }
}

# Transit Gateway with RAM sharing to specific OUs
module "transit_gateway_shared" {
  source = "../"

  name        = "myorg-prod"
  environment = "prod"

  # Create a new Transit Gateway
  create_transit_gateway = true
  amazon_side_asn        = 64513

  # Attach to hub VPC
  vpc_id                 = "vpc-0123456789abcdef0"
  subnet_ids             = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
  appliance_mode_support = "enable"

  # Share with specific OUs in the organization
  share_transit_gateway = true
  ram_principals = [
    "arn:aws:organizations::123456789012:ou/o-abc123/ou-workloads-prod",
    "arn:aws:organizations::123456789012:ou/o-abc123/ou-shared-services",
  ]

  tags = {
    Project = "network-hub"
  }
}

# Transit Gateway with DR region
module "transit_gateway_dr" {
  source = "../"

  name             = "myorg-prod"
  environment      = "prod"
  primary_region   = "ap-southeast-2"
  secondary_region = "ap-southeast-4"

  # Create a new Transit Gateway
  create_transit_gateway = true
  amazon_side_asn        = 64514

  # Primary region - attach to hub VPC
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]

  # Enable DR region
  dr_enabled    = true
  dr_vpc_id     = "vpc-0fedcba9876543210"
  dr_subnet_ids = ["subnet-ddd", "subnet-eee", "subnet-fff"]

  # Share both primary and DR TGWs with the same OUs
  share_transit_gateway = true
  ram_principals = [
    "arn:aws:organizations::123456789012:ou/o-abc123/ou-workloads-prod",
  ]

  tags = {
    Project = "network-hub"
  }
}

# Attach to an existing Transit Gateway (no creation)
module "transit_gateway_existing" {
  source = "../"

  name        = "myorg-nonprod"
  environment = "nonprod"

  # Use existing Transit Gateway
  create_transit_gateway = false
  transit_gateway_id     = "tgw-0123456789abcdef0"

  # Attach to hub VPC
  vpc_id     = "vpc-0abcdef1234567890"
  subnet_ids = ["subnet-111", "subnet-222", "subnet-333"]

  tags = {
    Project = "network-hub"
  }
}
