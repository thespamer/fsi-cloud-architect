###############################################################################
# AWS — Direct Connect (maximum resiliency) + Transit Gateway + multicast domain
#
# Illustrative. Pin your provider version and verify argument names.
#
# Topology encoded here:
#   - Two DX connections at two DIFFERENT locations, each with MACsec requested
#     -> Multi-Site Non-Redundant (99.9%). Add a second connection at each
#        location on a different device to reach Maximum Resiliency (99.99%).
#     Full resiliency-model table and SLA credits: 07-verified-facts.md §4.
#   - Direct Connect Gateway associated to a Transit Gateway
#   - Transit VIFs at MTU 8500 (NOT 9001 — that is private-VIF only);
#     07-verified-facts.md §4 has the full MTU-by-VIF-type table.
#   - Segmented TGW route tables
#   - A multicast domain for market data, in static-source mode;
#     constraints and quotas: 07-verified-facts.md §6.
###############################################################################

terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  amazon_side_asn  = 64513
  onprem_asn       = 65001
  dxgw_amazon_asn  = 64514

  # Transit VIF maximum is 8500. Private VIF would allow 9001.
  # Where multiple paths with different MTUs exist, AWS resolves to 1500 —
  # so make every path consistent.
  transit_vif_mtu = 8500
}

###############################################################################
# 1. Direct Connect connections — two locations
###############################################################################

resource "aws_dx_connection" "site_a" {
  name      = "dx-site-a-100g"
  bandwidth = "100Gbps"
  location  = var.dx_location_a # e.g. "EqDC2"

  # MACsec is available on 10, 100 and 400 Gbps connections at select locations.
  # Prefer it over IPsec: no MTU penalty.
  request_macsec = true

  tags = var.tags
}

resource "aws_dx_connection" "site_b" {
  name           = "dx-site-b-100g"
  bandwidth      = "100Gbps"
  location       = var.dx_location_b # a DIFFERENT location
  request_macsec = true
  tags           = var.tags
}

###############################################################################
# 2. Direct Connect Gateway + Transit Gateway
###############################################################################

resource "aws_dx_gateway" "main" {
  name            = "dxgw-prod"
  amazon_side_asn = local.dxgw_amazon_asn
}

resource "aws_ec2_transit_gateway" "main" {
  description                     = "prod transit"
  amazon_side_asn                 = local.amazon_side_asn

  # Explicit route tables, not the default. Segmentation is the point of a TGW.
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"

  dns_support     = "enable"
  vpn_ecmp_support = "enable"

  # Required if you intend to use TGW multicast for market data feeds.
  multicast_support = "enable"

  tags = merge(var.tags, { Name = "tgw-prod" })
}

resource "aws_dx_gateway_association" "tgw" {
  dx_gateway_id         = aws_dx_gateway.main.id
  associated_gateway_id = aws_ec2_transit_gateway.main.id

  # Advertise summaries, not per-subnet routes. Both sides cap prefix counts.
  allowed_prefixes = var.aws_summary_prefixes
}

###############################################################################
# 3. Transit VIFs
#
# BFD: AWS enables asynchronous BFD on the AWS side of a DX virtual interface
# automatically. You MUST configure it on your router (300 ms interval,
# multiplier 3 — 07-verified-facts.md §5a) for it to take effect. There is no
# Terraform argument for it; the on_prem_bfd_settings output below exists so a
# CI/CD pipeline or a runbook can pull the exact numbers instead of a human
# re-typing them from this comment.
#
# Inbound path preference: tag your advertisements from the on-prem router with
# the DX local preference communities (07-verified-facts.md §5a) —
#   7224:7100 = low, 7224:7200 = medium (AWS default if untagged), 7224:7300 = high
# See the dx_local_preference_communities output below for the same map.
###############################################################################

resource "aws_dx_transit_virtual_interface" "site_a" {
  connection_id  = aws_dx_connection.site_a.id
  dx_gateway_id  = aws_dx_gateway.main.id
  name           = "tvif-site-a"
  vlan           = 3001
  address_family = "ipv4"
  bgp_asn        = local.onprem_asn
  mtu            = local.transit_vif_mtu

  customer_address = "169.254.30.2/29"
  amazon_address   = "169.254.30.1/29"
  bgp_auth_key     = var.bgp_auth_key_a

  tags = var.tags
}

resource "aws_dx_transit_virtual_interface" "site_b" {
  connection_id    = aws_dx_connection.site_b.id
  dx_gateway_id    = aws_dx_gateway.main.id
  name             = "tvif-site-b"
  vlan             = 3002
  address_family   = "ipv4"
  bgp_asn          = local.onprem_asn
  mtu              = local.transit_vif_mtu
  customer_address = "169.254.30.10/29"
  amazon_address   = "169.254.30.9/29"
  bgp_auth_key     = var.bgp_auth_key_b

  tags = var.tags
}

###############################################################################
# 4. Segmented route tables
###############################################################################

resource "aws_ec2_transit_gateway_route_table" "prod" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  tags               = merge(var.tags, { Name = "tgw-rt-prod" })
}

resource "aws_ec2_transit_gateway_route_table" "shared" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  tags               = merge(var.tags, { Name = "tgw-rt-shared" })
}

resource "aws_ec2_transit_gateway_route_table" "hybrid" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id
  tags               = merge(var.tags, { Name = "tgw-rt-hybrid" })
}

###############################################################################
# 5. Multicast domain for market data
#
# Full mechanics and constraints: 07-verified-facts.md §6.
#
# Hard constraints to respect:
#   - Multicast does NOT traverse Direct Connect, Site-to-Site VPN, peering
#     attachments or TGW Connect. To get an on-prem feed in, bridge it with a
#     virtual router over GRE + PIM and use STATIC joins on the cloud side.
#   - TGW does not transparently pass IGMP joins from on-prem.
#   - Nitro instances can send and receive; non-Nitro can only receive.
#   - Fragmented packets are dropped. No fragmentation, ever.
#   - One multicast domain per subnet.
###############################################################################

resource "aws_ec2_transit_gateway_multicast_domain" "market_data" {
  transit_gateway_id = aws_ec2_transit_gateway.main.id

  # Static mode: you register sources and members explicitly. Required when the
  # source is an on-prem feed bridged in by a virtual router, because IGMP joins
  # do not cross the TGW.
  static_sources_support = "enable"
  igmpv2_support         = "disable"

  auto_accept_shared_associations = "disable"

  tags = merge(var.tags, { Name = "mcast-market-data" })
}

resource "aws_ec2_transit_gateway_multicast_domain_association" "receivers" {
  for_each = toset(var.multicast_subnet_ids)

  subnet_id                           = each.value
  transit_gateway_attachment_id       = var.multicast_vpc_attachment_id
  transit_gateway_multicast_domain_id = aws_ec2_transit_gateway_multicast_domain.market_data.id
}

resource "aws_ec2_transit_gateway_multicast_group_source" "feed" {
  group_ip_address                    = var.multicast_group
  network_interface_id                = var.source_eni_id # the bridging router's ENI
  transit_gateway_multicast_domain_id = aws_ec2_transit_gateway_multicast_domain.market_data.id
}

resource "aws_ec2_transit_gateway_multicast_group_member" "consumers" {
  for_each = toset(var.consumer_eni_ids)

  group_ip_address                    = var.multicast_group
  network_interface_id                = each.value
  transit_gateway_multicast_domain_id = aws_ec2_transit_gateway_multicast_domain.market_data.id
}

###############################################################################
# 6. Low-latency compute placement
###############################################################################

resource "aws_placement_group" "feed_handlers" {
  name     = "pg-feed-handlers"
  strategy = "cluster" # physical co-location; lowest latency
  tags     = var.tags
}

###############################################################################
# Variables
###############################################################################

variable "dx_location_a" {
  type        = string
  description = "DX location code for the first connection (e.g. 'EqDC2'). Must be a different physical facility from dx_location_b to earn the resiliency tier in 07-verified-facts.md §4."
}

variable "dx_location_b" {
  type        = string
  description = "DX location code for the second connection — a different facility from dx_location_a."
}

variable "aws_summary_prefixes" {
  type        = list(string)
  description = "Summary CIDR prefixes advertised to the Direct Connect Gateway via allowed_prefixes. Advertise summaries, not per-subnet routes — both sides of a DX session cap prefix counts."
}

variable "multicast_subnet_ids" {
  type        = list(string)
  description = "Subnet IDs to associate with the multicast domain as potential receivers. One multicast domain per subnet (07-verified-facts.md §6)."
}

variable "multicast_vpc_attachment_id" {
  type        = string
  description = "TGW VPC attachment ID the multicast subnet associations in §5 use."
}

variable "multicast_group" {
  type        = string
  description = "Multicast group IP address (e.g. 239.1.1.1) the source and consumers below join."
}

variable "source_eni_id" {
  type        = string
  description = "ENI ID of the on-prem-bridging virtual router that injects the feed — see 03-low-latency-market-data.md §5 Option B for the GRE+PIM bridge this assumes. Must be a Nitro instance; non-Nitro instances can only receive (07-verified-facts.md §6)."
}

variable "consumer_eni_ids" {
  type        = list(string)
  description = "ENI IDs of feed-handler instances registered as static multicast group members."
}

variable "bgp_auth_key_a" {
  type        = string
  sensitive   = true
  description = "BGP MD5 authentication key for the site-A transit VIF."
}

variable "bgp_auth_key_b" {
  type        = string
  sensitive   = true
  description = "BGP MD5 authentication key for the site-B transit VIF."
}

variable "tags" {
  type = map(string)
  default = {
    Environment        = "prod"
    DataClassification = "restricted"
    CostCentre         = "platform-network"
  }
  description = "Tags applied to every resource this module creates. Override per environment; DataClassification in particular should reflect what's actually carried (market data is frequently 'restricted' under the exchange's redistribution terms)."
}

###############################################################################
# Outputs
###############################################################################

output "dx_connection_ids" {
  value = {
    site_a = aws_dx_connection.site_a.id
    site_b = aws_dx_connection.site_b.id
  }
  description = "Direct Connect connection IDs, for CLI lookups (see examples/cli-cheatsheet.md) and for the LOA-CFA download step, which is not Terraform-managed."
}

output "transit_gateway_id" {
  value       = aws_ec2_transit_gateway.main.id
  description = "TGW ID, for attaching VPCs or wiring into a peered TGW in another region."
}

output "transit_vif_ids" {
  value = {
    site_a = aws_dx_transit_virtual_interface.site_a.id
    site_b = aws_dx_transit_virtual_interface.site_b.id
  }
  description = "Transit VIF IDs, for BGP session verification (see examples/cli-cheatsheet.md, 'Diagnostics')."
}

output "on_prem_bfd_settings" {
  value = {
    minimum_interval_ms = 300
    multiplier          = 3
  }
  description = "AWS-side BFD liveness parameters (07-verified-facts.md §5a). Not a Terraform-managed setting — AWS enables its side automatically, but a router config generator or a runbook can consume this output instead of a human copying it from a comment."
}

output "dx_local_preference_communities" {
  value = {
    low     = "7224:7100"
    medium  = "7224:7200" # AWS-applied default if a route carries no community
    high    = "7224:7300"
  }
  description = "AWS Direct Connect local-preference BGP communities (07-verified-facts.md §5a), for tagging on-prem advertisements to control inbound path preference — e.g. active leg = high, passive leg = low."
}
