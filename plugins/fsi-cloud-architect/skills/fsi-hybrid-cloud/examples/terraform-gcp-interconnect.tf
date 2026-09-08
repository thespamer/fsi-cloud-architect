###############################################################################
# GCP — Dedicated Interconnect + Cross-Cloud Interconnect to AWS
#
# Illustrative. Pin your provider version and verify argument names against the
# google provider docs for the version you use — Interconnect resources have
# gained arguments over time.
#
# Topology encoded here:
#   - Two Dedicated Interconnects in metro A, in DIFFERENT edge availability
#     domains  -> 99.9% tier for that metro
#   - Repeat this module in a second metro to reach the 99.99% tier
#   - One Cross-Cloud Interconnect pair to AWS
#   - Cloud Router with BFD on every BGP session and explicit route priority
###############################################################################

terraform {
  required_version = ">= 1.6"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

locals {
  region      = "us-east4"
  metro_a     = "iad-zone1-1" # edge availability domain 1
  metro_a_alt = "iad-zone2-1" # edge availability domain 2 — REQUIRED for SLA
  cloud_asn   = 64512
  onprem_asn  = 65001
}

###############################################################################
# 1. Dedicated Interconnect circuits — metro A, two edge availability domains
#
# Two connections in different edge availability domains, in ONE metro, is
# the 99.9% topology. Repeat this module in a second metro for 99.99% — both
# topologies are recorded in 07-verified-facts.md §1, which also has the
# 10G/100G/400G link-bundle counts if this circuit needs to scale beyond one
# link.
###############################################################################

resource "google_compute_interconnect" "metro_a_ead1" {
  name             = "dx-iad-ead1"
  interconnect_type = "DEDICATED"
  link_type        = "LINK_TYPE_ETHERNET_100G_LR"
  requested_link_count = 1
  location         = "https://www.googleapis.com/compute/v1/projects/${var.project_id}/global/interconnectLocations/iad-zone1-1"
  customer_name    = var.customer_name
  admin_enabled    = true
  noc_contact_email = var.noc_email

  # MACsec: request the feature at order time. Prefer this over IPsec where the
  # facility supports it — no MTU cost.
  requested_features = ["IF_MACSEC"]
}

resource "google_compute_interconnect" "metro_a_ead2" {
  name              = "dx-iad-ead2"
  interconnect_type = "DEDICATED"
  link_type         = "LINK_TYPE_ETHERNET_100G_LR"
  requested_link_count = 1
  location          = "https://www.googleapis.com/compute/v1/projects/${var.project_id}/global/interconnectLocations/iad-zone2-1"
  customer_name     = var.customer_name
  admin_enabled     = true
  noc_contact_email = var.noc_email
  requested_features = ["IF_MACSEC"]
}

###############################################################################
# 2. Cloud Router
#
# dynamic routing mode on the VPC (global vs regional) decides whether routes
# learned here are advertised from other regions. Global is usual for hybrid,
# but widens the blast radius of a bad advertisement.
###############################################################################

resource "google_compute_router" "hybrid" {
  name    = "cr-hybrid-${local.region}"
  region  = local.region
  network = var.vpc_self_link

  bgp {
    asn = local.cloud_asn

    # Advertise explicitly. Never rely on the default set for a hybrid edge.
    advertise_mode    = "CUSTOM"
    advertised_groups = ["ALL_SUBNETS"]

    dynamic "advertised_ip_range" {
      for_each = var.additional_advertised_ranges
      content {
        range       = advertised_ip_range.value.range
        description = advertised_ip_range.value.description
      }
    }

    keepalive_interval = 20 # seconds; BFD does the fast detection
  }
}

###############################################################################
# 3. VLAN attachments — one per interconnect
###############################################################################

resource "google_compute_interconnect_attachment" "metro_a_ead1" {
  name                     = "va-iad-ead1"
  region                   = local.region
  router                   = google_compute_router.hybrid.id
  type                     = "DEDICATED"
  interconnect             = google_compute_interconnect.metro_a_ead1.id
  mtu                      = var.attachment_mtu
  bandwidth                = "BPS_10G"
  vlan_tag8021q            = 1001
  candidate_subnets        = ["169.254.10.0/29"]
  admin_enabled            = true
  stack_type               = "IPV4_ONLY"
  description              = "Metro A / EAD1 — primary"
}

resource "google_compute_interconnect_attachment" "metro_a_ead2" {
  name              = "va-iad-ead2"
  region            = local.region
  router            = google_compute_router.hybrid.id
  type              = "DEDICATED"
  interconnect      = google_compute_interconnect.metro_a_ead2.id
  mtu               = var.attachment_mtu
  bandwidth         = "BPS_10G"
  vlan_tag8021q     = 1002
  candidate_subnets = ["169.254.10.8/29"]
  admin_enabled     = true
  stack_type        = "IPV4_ONLY"
  description       = "Metro A / EAD2 — secondary"
}

###############################################################################
# 4. BGP sessions — BFD on every one, priorities explicit
#
# advertised_route_priority: LOWER is preferred. Use it to make EAD1 primary.
###############################################################################

resource "google_compute_router_interface" "ead1" {
  name                    = "if-iad-ead1"
  router                  = google_compute_router.hybrid.name
  region                  = local.region
  interconnect_attachment = google_compute_interconnect_attachment.metro_a_ead1.self_link
}

resource "google_compute_router_peer" "ead1" {
  name                      = "peer-iad-ead1"
  router                    = google_compute_router.hybrid.name
  region                    = local.region
  interface                 = google_compute_router_interface.ead1.name
  peer_asn                  = local.onprem_asn
  peer_ip_address           = var.peer_ip_ead1
  advertised_route_priority = 100 # primary

  # BFD is the single highest-value setting on a hybrid session.
  # Without it, expect ~90 s of blackholed traffic on a circuit failure.
  #
  # Units are MILLISECONDS. Valid range 1000-30000, default 1000.
  # Multiplier 5-16, default 5. Session init mode defaults to DISABLED --
  # you must set it explicitly.
  # Full range/default table: 07-verified-facts.md §5a.
  #
  # PREREQUISITE: BFD on Cloud Router is only supported on Dedicated and
  # Partner Interconnect VLAN attachments running DATAPLANE VERSION 2.
  # It is NOT supported on HA VPN tunnels or router appliance (NCC) spokes.
  # Verify with:
  #   gcloud compute interconnects attachments describe VA --region=R \
  #     --format="value(dataplaneVersion)"
  bfd {
    session_initialization_mode = "ACTIVE"
    min_transmit_interval       = 1000 # ms
    min_receive_interval        = 1000 # ms
    multiplier                  = 5
  }

  md5_authentication_key {
    name = "peer-iad-ead1-md5"
    key  = var.bgp_md5_key_ead1
  }

  enable = true
}

resource "google_compute_router_interface" "ead2" {
  name                    = "if-iad-ead2"
  router                  = google_compute_router.hybrid.name
  region                  = local.region
  interconnect_attachment = google_compute_interconnect_attachment.metro_a_ead2.self_link
}

resource "google_compute_router_peer" "ead2" {
  name                      = "peer-iad-ead2"
  router                    = google_compute_router.hybrid.name
  region                    = local.region
  interface                 = google_compute_router_interface.ead2.name
  peer_asn                  = local.onprem_asn
  peer_ip_address           = var.peer_ip_ead2
  advertised_route_priority = 200 # secondary — higher value, less preferred

  bfd {
    session_initialization_mode = "ACTIVE"
    min_transmit_interval       = 1000 # ms
    min_receive_interval        = 1000 # ms
    multiplier                  = 5
  }

  md5_authentication_key {
    name = "peer-iad-ead2-md5"
    key  = var.bgp_md5_key_ead2
  }

  enable = true
}

###############################################################################
# 5. Cross-Cloud Interconnect to AWS
#
# Google provisions the circuit to the AWS remote location. Speeds available to
# AWS: 10, 100, 400 Gbps (07-verified-facts.md §2). Order in PAIRS across edge
# availability domains, and repeat in a second metro for the 99.99% tier.
#
# If you want minutes-not-weeks provisioning and 1-100 Gbps granularity, use
# PARTNER Cross-Cloud Interconnect for AWS instead — it carries built-in
# resiliency and needs no manual redundancy design.
###############################################################################

resource "google_compute_interconnect" "cci_aws_a" {
  name              = "cci-aws-iad-a"
  interconnect_type = "DEDICATED"
  link_type         = "LINK_TYPE_ETHERNET_100G_LR"
  requested_link_count = 1
  location          = "https://www.googleapis.com/compute/v1/projects/${var.project_id}/global/interconnectLocations/iad-zone1-1"
  remote_location   = var.aws_remote_location # e.g. an AWS us-east-1 remote location
  customer_name     = var.customer_name
  admin_enabled     = true
  noc_contact_email = var.noc_email
}

resource "google_compute_interconnect_attachment" "cci_aws_a" {
  name              = "va-cci-aws-a"
  region            = local.region
  router            = google_compute_router.hybrid.id
  type              = "DEDICATED"
  interconnect      = google_compute_interconnect.cci_aws_a.id
  mtu               = var.attachment_mtu
  bandwidth         = "BPS_10G"
  vlan_tag8021q     = 2001
  candidate_subnets = ["169.254.20.0/29"]
  admin_enabled     = true
  description       = "Cross-Cloud Interconnect to AWS us-east-1 — pair A"
}

###############################################################################
# Variables
###############################################################################

variable "project_id" {
  type        = string
  description = "GCP project ID the Interconnect resources are provisioned in."
}

variable "vpc_self_link" {
  type        = string
  description = "Self-link of the VPC the Cloud Router attaches to."
}

variable "customer_name" {
  type        = string
  description = "Customer name Google associates with the Interconnect order (appears on the circuit paperwork, not just in Terraform state)."
}

variable "noc_email" {
  type        = string
  description = "NOC contact email Google uses for maintenance and outage notifications on these circuits."
}

variable "attachment_mtu" {
  type        = number
  default     = 8896
  description = "VLAN attachment MTU. Valid values are 1440, 1460, 1500 or 8896 (07-verified-facts.md §1) — 8896 (jumbo) is unavailable on an encrypted attachment. Remember the end-to-end path minimum: an AWS transit VIF caps at 8500 (07-verified-facts.md §4), so a path crossing both clouds should not be set to 8896 on this side."
  validation {
    condition     = contains([1440, 1460, 1500, 8896], var.attachment_mtu)
    error_message = "attachment_mtu must be one of 1440, 1460, 1500 or 8896 — see 07-verified-facts.md §1."
  }
}

variable "peer_ip_ead1" {
  type        = string
  description = "On-prem/CPE BGP peer IP for the EAD1 (primary) session."
}

variable "peer_ip_ead2" {
  type        = string
  description = "On-prem/CPE BGP peer IP for the EAD2 (secondary) session."
}

variable "aws_remote_location" {
  type        = string
  description = "AWS Cross-Cloud Interconnect remote location identifier for the AWS side of the circuit — see 07-verified-facts.md §2 for supported remote clouds and port speeds."
}

variable "bgp_md5_key_ead1" {
  type        = string
  sensitive   = true
  description = "MD5 authentication key for the EAD1 BGP session. Rotate on the same schedule as the EAD2 key, on a maintenance window — a live-rotate on one session at a time keeps the other up."
}

variable "bgp_md5_key_ead2" {
  type        = string
  sensitive   = true
  description = "MD5 authentication key for the EAD2 BGP session."
}

variable "additional_advertised_ranges" {
  type = list(object({
    range       = string
    description = string
  }))
  default     = []
  description = "Extra CIDR ranges to advertise beyond ALL_SUBNETS, e.g. a PUPI range or a summarized range not backed by an actual subnet."
}

###############################################################################
# Outputs
###############################################################################

output "cloud_router_name" {
  value       = google_compute_router.hybrid.name
  description = "Cloud Router name, for CLI lookups (see examples/cli-cheatsheet.md, 'Cloud Router and BGP')."
}

output "attachment_self_links" {
  value = {
    metro_a_ead1 = google_compute_interconnect_attachment.metro_a_ead1.self_link
    metro_a_ead2 = google_compute_interconnect_attachment.metro_a_ead2.self_link
    cci_aws_a    = google_compute_interconnect_attachment.cci_aws_a.self_link
  }
  description = "Self-links of every VLAN attachment this module creates, for wiring into an NCC hub spoke or a downstream module."
}

output "effective_mtu" {
  value       = var.attachment_mtu
  description = "The MTU actually applied to every attachment in this module — surface it so a CI check can compare it against a downstream AWS module's transit_vif_mtu output and fail before a mismatch reaches production."
}

output "resiliency_tier" {
  value       = "99.9% (single metro, two edge availability domains) — attach a second metro's worth of these resources for 99.99% (07-verified-facts.md §1)"
  description = "Human-readable statement of which SLA topology this module's resource count actually satisfies, so a design review doesn't have to re-derive it from the resource list."
}
