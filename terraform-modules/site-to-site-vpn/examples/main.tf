################################################################################
# site-to-site-vpn Example
# Two-domain deployment: IT and OT networks, each with an on-premises and an
# Azure VPN endpoint attached to a shared Transit Gateway.
#
# Prerequisites (supplied by core-network-hub / transit-gateway module outputs):
#   - transit_gateway_id
#   - hub_attachment_id        (hub VPC TGW attachment)
#   - inspection_route_table_id
#   - environment_route_table_ids (map of env → RT ID)
################################################################################

terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0, < 6.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

# DR provider — only used when dr_enabled = true
provider "aws" {
  alias  = "dr"
  region = "eu-west-2"
}

module "site_to_site_vpn" {
  source = "../"

  name        = "acme-hub"
  environment = "prod"

  tags = {
    CostCentre = "networking"
    Owner      = "platform-team"
  }

  # --------------------------------------------------------------------------
  # VPN Connections
  # IT domain: on-premises DC and Azure Virtual WAN hub
  # OT domain: on-premises OT network and Azure hub (separate VPN for isolation)
  # --------------------------------------------------------------------------
  vpn_connections = {
    it_onprem = {
      bgp_asn    = 65001
      ip_address = "203.0.113.10"
      # BGP — routes propagated automatically; no destination_cidr_blocks needed
    }

    it_azure = {
      bgp_asn    = 65515 # Azure VPN Gateway default ASN
      ip_address = "203.0.113.20"
    }

    ot_onprem = {
      bgp_asn            = 65002
      ip_address         = "203.0.113.30"
      static_routes_only = true
      destination_cidr_blocks = [
        "172.16.0.0/16",
        "172.17.0.0/16",
      ]
    }

    ot_azure = {
      bgp_asn    = 65515
      ip_address = "203.0.113.40"
      # Disabled — not yet provisioned; kept in config for future enablement
      enabled = false
    }
  }

  # --------------------------------------------------------------------------
  # TGW references — wire up to existing hub infrastructure
  # --------------------------------------------------------------------------
  transit_gateway_id        = "tgw-0abc1234def56789a"
  hub_attachment_id         = "tgw-attach-0abc1234def56789a"
  inspection_route_table_id = "tgw-rtb-0abc1234def56789a"

  environment_route_table_ids = {
    dev     = "tgw-rtb-0111111111111111a"
    preprod = "tgw-rtb-0222222222222222a"
    prod    = "tgw-rtb-0333333333333333a"
  }

  shared_services_route_table_id = "tgw-rtb-0444444444444444a"

  # Use a supernet instead of 0.0.0.0/0 in the VPN route table default route
  # so non-spoke traffic (e.g. internet) is not accidentally blackholed.
  spoke_cidr_supernet = "10.0.0.0/8"

  # --------------------------------------------------------------------------
  # DR — disabled in this example; set dr_enabled = true and populate
  # dr_* variables to enable cross-region VPN redundancy.
  # --------------------------------------------------------------------------
  dr_enabled = false
}

################################################################################
# Outputs
################################################################################

output "vpn_connection_ids" {
  description = "Map of logical VPN name to AWS VPN connection ID"
  value       = module.site_to_site_vpn.vpn_connection_ids
}

output "vpn_tunnel_addresses" {
  description = "Tunnel 1 and 2 outside addresses per VPN connection"
  value = {
    for k in keys(module.site_to_site_vpn.vpn_connection_ids) : k => {
      tunnel1 = module.site_to_site_vpn.vpn_tunnel1_addresses[k]
      tunnel2 = module.site_to_site_vpn.vpn_tunnel2_addresses[k]
    }
  }
}

output "vpn_route_table_id" {
  description = "Remote-connectivity TGW route table ID"
  value       = module.site_to_site_vpn.vpn_route_table_id
}
