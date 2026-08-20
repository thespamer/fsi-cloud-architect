###############################################################################
# AWS — Direct Connect (maximum resiliency) + Transit Gateway + multicast domain
#
# Illustrative. Pin your provider version and verify argument names.
#
# Topology encoded here:
#   - Two DX connections at two DIFFERENT locations, each with MACsec requested
#     -> Multi-Site Non-Redundant (99.9%). Add a second connection at each
#        location on a different device to reach Maximum Resiliency (99.99%).
#   - Direct Connect Gateway associated to a Transit Gateway
#   - Transit VIFs at MTU 8500 (NOT 9001 — that is private-VIF only)
#   - Segmented TGW route tables
#   - A multicast domain for market data, in static-source mode
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
# automatically. You MUST configure it on your router (typical: 300 ms interval,
# multiplier 3) for it to take effect. There is no Terraform argument for it.
#
# Inbound path preference: tag your advertisements from the on-prem router with
# the DX local preference communities —
#   7224:7100 = low, 7224:7200 = medium, 7224:7300 = high
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

variable "dx_location_a" { type = string }
variable "dx_location_b" { type = string }
variable "aws_summary_prefixes" { type = list(string) }
variable "multicast_subnet_ids" { type = list(string) }
variable "multicast_vpc_attachment_id" { type = string }
variable "multicast_group" { type = string }
variable "source_eni_id" { type = string }
variable "consumer_eni_ids" { type = list(string) }

variable "bgp_auth_key_a" {
  type      = string
  sensitive = true
}

variable "bgp_auth_key_b" {
  type      = string
  sensitive = true
}

variable "tags" {
  type = map(string)
  default = {
    Environment        = "prod"
    DataClassification = "restricted"
    CostCentre         = "platform-network"
  }
}
