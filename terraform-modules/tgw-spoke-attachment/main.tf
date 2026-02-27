################################################################################
# TGW Spoke Attachment Route Table Wiring
#
# This module wires a spoke VPC TGW attachment into the per-environment TGW
# route table segmentation model. It must be called from the hub/networking
# account (which owns the TGW and the route tables).
#
# For each spoke attachment it:
#   1. Associates the attachment with its environment route table
#   2. Propagates the spoke CIDR into the inspection route table (so the
#      firewall hub can return traffic back to the spoke)
#   3. Optionally propagates the spoke CIDR into the shared services route
#      table (so shared services VPCs can respond to requests from this spoke)
################################################################################

locals {
  common_tags = merge(
    var.tags,
    {
      Environment   = var.environment
      ManagedBy     = "terraform"
      Module        = "tgw-spoke-attachment"
      ModuleVersion = local.module_version
    }
  )

  create_shared_services_propagation = var.shared_services_route_table_id != ""
}

# Associate spoke attachment with its environment-specific route table.
# All outbound traffic from this spoke routes via 0.0.0.0/0 → inspection.
resource "aws_ec2_transit_gateway_route_table_association" "spoke_env" {
  transit_gateway_attachment_id  = var.attachment_id
  transit_gateway_route_table_id = var.environment_route_table_id
}

# Propagate the spoke CIDR into the inspection route table so the firewall
# hub can forward return traffic back to the spoke after policy enforcement.
resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_to_inspection" {
  transit_gateway_attachment_id  = var.attachment_id
  transit_gateway_route_table_id = var.inspection_route_table_id
}

# Propagate the spoke CIDR into the shared services route table so that shared
# services VPCs can initiate or respond to connections to/from this spoke.
resource "aws_ec2_transit_gateway_route_table_propagation" "spoke_to_shared_services" {
  count = local.create_shared_services_propagation ? 1 : 0

  transit_gateway_attachment_id  = var.attachment_id
  transit_gateway_route_table_id = var.shared_services_route_table_id
}
