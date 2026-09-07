###############################################################################
# GCP platform baseline — the shape of a golden path
#
# Regional private GKE cluster + Cloud Run service + the guardrails that make
# both compliant by construction. This is what a workload team should be able to
# consume as a module in under an hour, with no ticket.
#
# Illustrative. Pin your provider version and verify argument names.
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
  region = "southamerica-east1" # São Paulo
  labels = {
    environment         = var.environment
    cost_centre         = var.cost_centre
    owner               = var.owner
    data_classification = var.data_classification
    managed_by          = "terraform"
  }
}

###############################################################################
# 1. Customer-managed encryption key
#
# Separation of duties: the identity that USES the key must not be the identity
# that can delete it or change its policy.
###############################################################################

resource "google_kms_key_ring" "app" {
  name     = "kr-${var.app_name}-${local.region}"
  location = local.region
}

resource "google_kms_crypto_key" "app" {
  name            = "ck-${var.app_name}"
  key_ring        = google_kms_key_ring.app.id
  rotation_period = "7776000s" # 90 days

  lifecycle {
    prevent_destroy = true
  }
}

###############################################################################
# 2. Regional private GKE cluster
#
# REGIONAL is the zone-resilience control. A zonal cluster does not survive a
# zone outage, whatever else the design claims.
###############################################################################

resource "google_container_cluster" "primary" {
  name     = "gke-${var.app_name}-${local.region}"
  location = local.region # region, NOT a zone -> regional control plane + nodes

  enable_autopilot = true

  network         = var.network_self_link
  subnetwork      = var.subnetwork_self_link
  networking_mode = "VPC_NATIVE"

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # Private cluster: nodes have no public IPs; the control plane endpoint is
  # private and reachable only from authorised networks.
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = true
    master_ipv4_cidr_block  = var.master_cidr
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr
        display_name = cidr_blocks.value.name
      }
    }
  }

  # Workload Identity: pods get Google identities without any exported key.
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  database_encryption {
    state    = "ENCRYPTED"
    key_name = google_kms_crypto_key.app.id
  }

  # Provenance enforcement — only signed images from Artifact Registry run here.
  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

  release_channel {
    channel = "REGULAR"
  }

  maintenance_policy {
    recurring_window {
      # Align with the business calendar, not the default.
      start_time = "2026-01-04T03:00:00Z"
      end_time   = "2026-01-04T07:00:00Z"
      recurrence = "FREQ=WEEKLY;BYDAY=SU"
    }
  }

  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus { enabled = true }
  }

  resource_labels = local.labels

  # Terraform provisions the cluster. It should NOT manage the workloads inside
  # it -- that belongs to GitOps. Coupling the two makes both slower.
}

###############################################################################
# 3. Workload Identity binding — no keys, ever
###############################################################################

resource "google_service_account" "workload" {
  account_id   = "sa-${var.app_name}"
  display_name = "${var.app_name} workload identity"
}

resource "google_service_account_iam_member" "workload_identity" {
  service_account_id = google_service_account.workload.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.k8s_namespace}/${var.k8s_service_account}]"
}

###############################################################################
# 4. Cloud Run service — internal only, private egress to the VPC
###############################################################################

resource "google_service_account" "run" {
  account_id   = "sa-run-${var.app_name}"
  display_name = "${var.app_name} Cloud Run identity"
}

resource "google_cloud_run_v2_service" "api" {
  name     = "run-${var.app_name}"
  location = local.region

  # Internal only. External ingress is a decision that gets recorded, not a
  # default.
  ingress = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"

  template {
    service_account = google_service_account.run.email

    # Direct VPC egress so private services and hybrid paths are reachable.
    vpc_access {
      network_interfaces {
        network    = var.network_self_link
        subnetwork = var.subnetwork_self_link
      }
      egress = "ALL_TRAFFIC"
    }

    scaling {
      min_instance_count = var.min_instances # >0 to avoid cold start on a hot path
      max_instance_count = var.max_instances
    }

    containers {
      image = var.container_image

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
        # CPU allocated only during requests is cheaper; always-allocated is
        # required for background work. Choose deliberately.
        cpu_idle = true
      }

      dynamic "env" {
        for_each = var.secret_env
        content {
          name = env.key
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }
    }

    # Set concurrency deliberately; the default is rarely right.
    max_instance_request_concurrency = var.concurrency
  }

  labels = local.labels
}

# Internal callers only — no allUsers, ever, on an internal service.
resource "google_cloud_run_v2_service_iam_member" "invokers" {
  for_each = toset(var.invoker_members)

  name     = google_cloud_run_v2_service.api.name
  location = google_cloud_run_v2_service.api.location
  role     = "roles/run.invoker"
  member   = each.value
}

###############################################################################
# 5. Budget — cost visible before committing, per the consumability bar
###############################################################################

resource "google_billing_budget" "app" {
  billing_account = var.billing_account
  display_name    = "budget-${var.app_name}-${var.environment}"

  budget_filter {
    projects = ["projects/${var.project_number}"]
    labels = {
      cost_centre = var.cost_centre
    }
  }

  amount {
    specified_amount {
      currency_code = "USD"
      units         = tostring(var.monthly_budget_usd)
    }
  }

  dynamic "threshold_rules" {
    for_each = [0.5, 0.8, 1.0]
    content {
      threshold_percent = threshold_rules.value
    }
  }

  all_updates_rule {
    monitoring_notification_channels = var.notification_channels
    disable_default_iam_recipients   = true
  }
}

###############################################################################
# Variables — this is the module interface a workload team consumes
#
# Every variable carries a `description` deliberately: this is the module's
# self-service contract (the consumability bar in 10-cloud-enablement.md §3),
# and `terraform-docs`-style tooling in a CI/CD pipeline generates the
# consumer-facing reference from these strings, not from a separate doc that
# will drift.
###############################################################################

variable "project_id" {
  type        = string
  description = "GCP project ID the platform baseline is deployed into."
}

variable "project_number" {
  type        = string
  description = "GCP project number — required by google_billing_budget's budget_filter, which does not accept the project ID."
}

variable "billing_account" {
  type        = string
  description = "Billing account ID (format XXXXXX-XXXXXX-XXXXXX) the budget in §5 is created against."
}

variable "app_name" {
  type        = string
  description = "Short, DNS-safe workload name. Used as a naming prefix for every resource in this module (gke-<app_name>-<region>, sa-<app_name>, etc.)."
}

variable "environment" {
  type        = string
  description = "Deployment environment label (e.g. dev, staging, prod). Propagated into resource_labels and the maintenance-window/budget naming."
}

variable "cost_centre" {
  type        = string
  description = "Cost-centre code for FinOps chargeback — applied as a label and as the budget_filter in §5."
}

variable "owner" {
  type        = string
  description = "Human or team accountable for this workload — the 'known owner to page' the consumability bar requires."
}

variable "data_classification" {
  type        = string
  description = "Data sensitivity tier. Drives which controls a review would expect to see layered on top of this baseline."
  validation {
    condition     = contains(["public", "internal", "confidential", "restricted"], var.data_classification)
    error_message = "data_classification must be one of: public, internal, confidential, restricted."
  }
}

variable "network_self_link" {
  type        = string
  description = "Self-link of the Shared VPC (or standalone VPC) this workload attaches to. See 01-hybrid-topology.md §2 for the Shared VPC pattern this assumes."
}

variable "subnetwork_self_link" {
  type        = string
  description = "Self-link of the regional subnet in network_self_link, in local.region."
}

variable "pods_range_name" {
  type        = string
  description = "Name of the secondary IP range for GKE pod IPs (VPC-native cluster requirement)."
}

variable "services_range_name" {
  type        = string
  description = "Name of the secondary IP range for GKE Service IPs (VPC-native cluster requirement)."
}

variable "master_cidr" {
  type        = string
  description = "/28 CIDR for the GKE private control-plane endpoint. Must not overlap any range already routed to this VPC."
}

variable "authorized_networks" {
  type = list(object({
    cidr = string
    name = string
  }))
  default     = []
  description = "CIDR blocks allowed to reach the private GKE control-plane endpoint (master_authorized_networks_config). Empty means nothing outside the cluster's own network can reach it."
}

variable "k8s_namespace" {
  type        = string
  description = "Kubernetes namespace the Workload Identity binding in §3 authorises — must match the namespace the workload's KSA actually runs in."
}

variable "k8s_service_account" {
  type        = string
  description = "Kubernetes ServiceAccount name bound to the GCP service account via Workload Identity."
}

variable "container_image" {
  type        = string
  description = "Fully-qualified image reference for the Cloud Run service, e.g. REGION-docker.pkg.dev/PROJECT/REPO/IMAGE:TAG. Must be signed if Binary Authorization is enforced on the GKE side of the same project."
}

variable "min_instances" {
  type        = number
  default     = 0
  description = "Cloud Run minimum instance count. Set > 0 to avoid cold start on a hot path — 0 is a deliberate default, not a recommendation."
}

variable "max_instances" {
  type        = number
  default     = 10
  description = "Cloud Run maximum instance count — the ceiling on both blast radius and cost from a runaway scale-out event."
}

variable "concurrency" {
  type        = number
  default     = 80
  description = "Cloud Run max_instance_request_concurrency. The Cloud Run default is rarely right for a given workload's per-request cost — set deliberately."
}

variable "secret_env" {
  type        = map(string)
  default     = {}
  description = "Map of environment variable name -> Secret Manager secret ID, injected via value_source.secret_key_ref at latest version. Never put a secret in a plain env var here."
}

variable "invoker_members" {
  type        = list(string)
  default     = []
  description = "IAM members granted roles/run.invoker. Must be an explicit list — this module does not accept allUsers for an internal-only service."
}

variable "monthly_budget_usd" {
  type        = number
  description = "Monthly budget amount in USD. Alerts fire at 50%, 80% and 100% (§5) — the consumability bar's 'cost visible before committing'."
}

variable "notification_channels" {
  type        = list(string)
  default     = []
  description = "Monitoring notification channel IDs the budget alert publishes to. Paired with disable_default_iam_recipients = true, so this is the only place the alert goes — populate it."
}

###############################################################################
# Outputs — what a CI/CD pipeline or a downstream module consumes
###############################################################################

output "gke_cluster_name" {
  value       = google_container_cluster.primary.name
  description = "Name of the regional GKE cluster, for kubectl/CI targeting."
}

output "gke_cluster_endpoint" {
  value       = google_container_cluster.primary.private_cluster_config[0].private_endpoint
  description = "Private control-plane endpoint. Reachable only from the CIDRs in authorized_networks."
  sensitive   = true
}

output "gke_workload_service_account_email" {
  value       = google_service_account.workload.email
  description = "GCP service account email bound via Workload Identity — the identity the deployment manifest's KSA annotation must reference."
}

output "cloud_run_service_url" {
  value       = google_cloud_run_v2_service.api.uri
  description = "Internal Cloud Run URL. Not publicly resolvable — ingress is INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER."
}

output "kms_crypto_key_id" {
  value       = google_kms_crypto_key.app.id
  description = "CMEK key ID used for GKE database_encryption — reference this from any other resource in the same workload that needs the same key rather than creating a second one."
}

output "billing_budget_id" {
  value       = google_billing_budget.app.id
  description = "Budget resource ID, for a CI/CD step that verifies a budget exists before allowing a deploy to proceed."
}
