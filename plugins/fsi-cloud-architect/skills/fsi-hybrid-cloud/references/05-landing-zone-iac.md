# Landing Zone, IaC, Observability and FinOps

The platform layer beneath the architecture: how the estate is organised, how it
is built, how it is watched, and how its cost is controlled.

---

## 1. Organisational Structure

### AWS

```
Root
├── Security OU
│   ├── log-archive          (immutable central logs)
│   └── security-tooling     (Security Hub, GuardDuty delegated admin)
├── Infrastructure OU
│   ├── network-prod         (TGW / Cloud WAN, DX Gateway, inspection)
│   ├── network-nonprod
│   └── shared-services      (DNS, AD, CI runners, artifact stores)
├── Workloads OU
│   ├── Prod OU              (one account per workload, per region domain)
│   └── NonProd OU
├── Sandbox OU               (time-boxed, spend-capped, no prod connectivity)
└── Suspended OU             (deny-all SCP, decommissioning)
```

### GCP

```
Organization
├── folders/security         → projects: log-archive, security-tooling
├── folders/infrastructure   → projects: net-hub-prod (Shared VPC host + NCC),
│                                        net-hub-nonprod, shared-services
├── folders/workloads
│   ├── folders/prod         → one project per workload (Shared VPC service projects)
│   └── folders/nonprod
├── folders/sandbox          → budget-capped, no VPC attachment
└── folders/decommission     → restrictive org policies
```

**Principles that carry across both:**

- **The account/project is the blast-radius boundary.** One workload, one
  environment, one boundary. Resist shared "kitchen sink" accounts.
- **Network lives in dedicated accounts/projects** owned by the platform team.
  Workload teams consume subnets and attachments, they do not create transit.
- **Logging is a separate, restricted destination** that workload identities can
  write to and cannot read or delete from.
- **Sandbox is disconnected.** No route to production networks, hard budget cap,
  automatic expiry.
- **Guardrails attach to the OU/folder**, so a new account/project inherits them
  before anyone can deploy into it.

---

## 2. Infrastructure as Code

**Structure the repository around blast radius, not around cloud services.**

```
infra/
├── modules/
│   ├── network/
│   │   ├── gcp-interconnect-attachment/
│   │   ├── gcp-ncc-spoke/
│   │   ├── aws-dx-vif/
│   │   ├── aws-tgw-attachment/
│   │   └── cross-cloud-link/
│   ├── security/
│   │   ├── kms-cmek/
│   │   ├── object-lock-bucket/
│   │   └── org-guardrails/
│   └── workload/
│       ├── gke-service/          # namespace, workload identity, netpol, ILB
│       ├── cloud-run-service/    # service, SA, VPC egress, secrets, obs
│       └── tick-archive/         # CMEK bucket, lifecycle, retention lock
├── live/
│   ├── prod/
│   │   ├── us-east/{gcp,aws}/
│   │   └── eu-west/{gcp,aws}/
│   └── nonprod/
└── policy/                       # OPA / Sentinel / gatekeeper policies
```

**Standards:**

| Concern | Standard |
| --- | --- |
| Tool | **Terraform** (or OpenTofu) as the default for infrastructure; **Ansible** for configuration management and anything that must converge inside a VM or appliance; **Python** and **GoLang** for platform tooling, controllers and glue. Provider-native (CDK, Config Connector) only where it earns its keep |
| State | Remote, encrypted with CMK/CMEK, locked, one state per blast-radius unit — never one state for the whole estate |
| Modules | Versioned and pinned. `ref=v1.4.2`, never `main` |
| Secrets | Never in state or variables files. Reference the secret store at runtime |
| Drift | Detected on a schedule and alerted; drift in network or security modules is an incident |
| Policy as code | OPA/Conftest or Sentinel in CI, blocking merges that violate guardrails |
| Plan review | Every production plan reviewed by someone other than the author; plan output attached to the change record |

**Cross-cloud modules deserve special care.** A module that provisions both sides
of a cross-cloud link couples two providers' state. Prefer two modules with an
explicit contract (the peering parameters) passed between them, so one side can
be rebuilt without touching the other.

**Network changes are the highest-risk changes in the estate.** Gate them:
separate pipeline, separate approvers, change window, tested rollback,
post-change synthetic validation.

### Where each tool belongs

| Layer | Tool | Note |
| --- | --- | --- |
| Cloud resources — networks, projects, clusters, IAM, storage | Terraform | Declarative, stateful, planned and reviewed |
| Inside-the-VM configuration, appliance config, on-prem edge routers | Ansible | Where there is no API-declarative model, or the target is not cloud |
| Kubernetes workloads | Kubernetes manifests / Helm, delivered by GitOps | Not Terraform. Terraform provisions the cluster; it should not manage the pods |
| Platform controllers, policy tooling, cost tooling, migration automation | Python or GoLang | Go for anything long-running or distributed; Python for analysis and one-shot tooling |
| Policy enforcement | OPA/Conftest or Sentinel in CI | Blocks the merge, not the deploy |

**The boundary that causes the most pain:** Terraform managing Kubernetes
resources. It couples cluster lifecycle to workload lifecycle and makes both
slower. Terraform up to the cluster and the namespace; GitOps from there.

---

## 3. Runtime Standards — GKE, Cloud Run, Lambda

The container and serverless runtimes are where workload teams actually live.
Standardise them or every team invents a different shape.

### GKE

| Concern | Standard |
| --- | --- |
| Cluster type | **Regional** clusters for anything beyond scratch — this is the zone-resilience control (see `09-ha-dr-patterns.md` §3) |
| Mode | Autopilot by default; Standard where you need node-level control (GPUs with specific topology, custom kernels, latency tuning) |
| Identity | **Workload Identity** — never node service accounts, never exported keys |
| Network | Private clusters, authorised networks for the control plane, network policy enforced by default |
| Ingress | Internal load balancer (ILB) by default; external only with an explicit decision recorded |
| Multi-tenancy | Namespace-per-service with quotas and network policy. Cluster-per-business-unit only when the isolation requirement is real |
| Images | Artifact Registry only, signed, with **Binary Authorization** enforcing provenance |
| Upgrades | Release channel chosen deliberately; maintenance windows aligned with the business calendar, not the default |

### Cloud Run

| Concern | Standard |
| --- | --- |
| Ingress | Internal or internal-and-load-balancer by default |
| Egress to VPC | Direct VPC egress or a connector, so private services and hybrid paths are reachable |
| Identity | A dedicated service account per service, least privilege |
| Concurrency and CPU | Set deliberately — the defaults are rarely right, and CPU-always-allocated versus request-only changes both cost and behaviour |
| GPU workloads | See `08-genai-ml-platform.md` §2 — scale-to-zero is the reason to choose this over an endpoint |

### Lambda (AWS side)

Use for event glue, orchestration and light API work. Not for model hosting, not
for anything with a sustained high duty cycle where a container runtime is
cheaper. Standardise on: VPC attachment only where it needs private resources
(it costs cold-start time), a dedicated execution role per function, and
structured logging to the central archive.

---

## 4. CI/CD

- **Keyless authentication from CI to cloud.** GitHub OIDC → AWS IAM role and →
  GCP workload identity pool. No long-lived credentials in the CI system.
- **Separate pipelines per environment** with promotion, not per-environment
  branches with divergent code.
- **Artefacts are immutable and signed.** Build once, promote the same artefact.
- **Deployment evidence** — who deployed what, when, from which commit, with
  which approval — is SOX ITGC evidence. Make it queryable.
- **Automated rollback** defined for every production deployment, and rehearsed.

---

## 5. Observability

### The four things to instrument in a hybrid estate

1. **Hybrid path health** — BGP state, route counts, interface utilisation at
   ≤10 s resolution, errors and discards, per circuit. Synthetic probes running
   continuously across every path, measuring latency, loss and max-MTU
   reachability.
2. **Application latency at the percentiles that matter** — p50 is a comfort
   metric; p99 and p99.9 are the SLA. Histogram, not average.
3. **Clock offset** — continuous, retained, alerted. Regulatory evidence.
4. **Cost** — daily, by tag/label, with anomaly detection. Egress broken out
   separately from compute.

### Tooling

| Layer | AWS | GCP | Cross-cloud |
| --- | --- | --- | --- |
| Metrics | CloudWatch | Cloud Monitoring | Prometheus + Grafana, or a commercial APM |
| Traces | X-Ray | Cloud Trace | OpenTelemetry as the collection standard |
| Logs | CloudWatch Logs → central archive | Cloud Logging → central archive | Same archive |
| Network | VPC Flow Logs, Reachability Analyzer, Network Manager | VPC Flow Logs, Network Intelligence Center, Connectivity Tests | Synthetic probes |
| Synthetics | CloudWatch Synthetics | Cloud Monitoring uptime checks | Own probes on both sides of every circuit |

**Standardise on OpenTelemetry** for application telemetry. It is the only
practical way to get one trace across a request that starts in GCP, crosses a
private circuit and finishes in AWS — and it keeps the exit path open.

**Correlate provider status with your own telemetry.** Ingest both clouds' health
feeds into the same dashboard your on-call uses, so "is it us or them" is
answered in seconds.

---

## 6. FinOps

### The costs that dominate an FSI hybrid estate

| Cost | Control |
| --- | --- |
| **Cross-cloud and internet egress** | Private circuits with fixed port pricing; keep fan-out where egress is cheapest; compress and batch bulk transfers |
| **Always-on latency-sensitive compute** | Committed use discounts / Savings Plans — this fleet does not scale down, so commit hard |
| **Bursty analytics** | Spot/preemptible with checkpointing; never for latency-critical paths |
| **Tick archive storage** | Lifecycle to colder tiers, subject to retention immutability constraints |
| **Data processing services** | Watch per-request and per-GB-scanned pricing; partition and columnarise |
| **Idle non-prod** | Scheduled shutdown; sandbox expiry |

### Practices

- **Tag/label at creation, enforced by policy.** Cost centre, environment, data
  classification, owner, application. Untagged resources are a policy violation,
  not a cleanup task.
- **Showback per team, monthly**, with the egress line broken out. Teams optimise
  what they can see.
- **Unit economics** — cost per million messages processed, cost per client API
  call, cost per TB of tick data retained. These are the numbers that survive a
  budget conversation; absolute spend is not.
- **Anomaly detection with alerting**, not monthly review. A misconfigured
  cross-cloud replication job discovered on the invoice is a bad month.
- **Model before you build.** Every architecture option in a design document
  carries a 36-month cost estimate with its assumptions stated.
- **Commitment strategy** — layer Savings Plans / CUDs against the stable base
  and leave the burst on-demand. Review the coverage ratio quarterly.

---

## 7. Platform Team Operating Model

**What the platform team owns:** transit networking, guardrails, landing zone,
shared services, IaC modules, observability platform, cost governance.

**What workload teams own:** their account/project contents, their application
architecture within the guardrails, their SLOs, their on-call.

**The contract between them:** versioned modules, documented network attachment
process with a stated lead time, published guardrails with an exception process,
and a self-service path for everything that does not need review.

**Golden paths beat approval gates.** Make the compliant way the easy way — a
module that provisions a correctly configured, logged, encrypted, tagged
environment in one command does more for compliance than a review board.

**Exception register.** Every deviation from the guardrails recorded with the
compensating control, the owner and an expiry date. Exceptions without expiry
become permanent architecture by default.
