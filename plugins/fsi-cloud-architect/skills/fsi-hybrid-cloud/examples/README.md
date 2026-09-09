# Examples Index

What's in this directory, and — for each Terraform example — the topology
it actually provisions, so a reader doesn't have to trace resource blocks to
see the shape. Every diagram cites the file it describes; if the two drift
apart, the `.tf` file is authoritative and this diagram is stale.

---

## `terraform-gcp-interconnect.tf`

Two Dedicated Interconnect circuits in one metro, across two edge
availability domains (the 99.9% SLA topology — `07-verified-facts.md` §1),
plus one Cross-Cloud Interconnect pair to AWS. Cloud Router runs BGP with
BFD and explicit route priority on every session.

```mermaid
graph LR
  subgraph ONPREM["On-prem / colo router"]
    RTR[Peer router<br/>local.onprem_asn = 65001]
  end

  subgraph GCP["Google Cloud — local.region"]
    CR[Cloud Router: hybrid<br/>ASN 64512]
    IC1[Interconnect: dx-iad-ead1<br/>EAD1]
    IC2[Interconnect: dx-iad-ead2<br/>EAD2]
    VA1[VLAN attachment: va-iad-ead1<br/>mtu = var.attachment_mtu]
    VA2[VLAN attachment: va-iad-ead2<br/>mtu = var.attachment_mtu]
    ICCCI[Interconnect: cci-aws-iad-a<br/>Cross-Cloud Interconnect]
    VACCI[VLAN attachment: va-cci-aws-a]

    IC1 --- VA1 --- CR
    IC2 --- VA2 --- CR
    ICCCI --- VACCI --- CR
  end

  subgraph AWS["AWS — var.aws_remote_location"]
    AWSEP[Cross-Cloud Interconnect<br/>remote endpoint]
  end

  RTR -->|BGP + BFD<br/>peer-iad-ead1, priority 100 primary| IC1
  RTR -->|BGP + BFD<br/>peer-iad-ead2, priority 200 secondary| IC2
  ICCCI -->|Google-provisioned circuit| AWSEP
```

Repeat this module in a second metro to reach the 99.99% tier — this
diagram, like the file, encodes one metro.

---

## `terraform-aws-directconnect.tf`

Two DX connections at two different physical locations (Multi-Site
Non-Redundant, 99.9% — `07-verified-facts.md` §4), associated to a Direct
Connect Gateway and a Transit Gateway with segmented route tables, plus a
static-mode multicast domain for a bridged on-prem market-data feed
(`07-verified-facts.md` §6) and a cluster placement group for the feed
handlers that consume it.

```mermaid
graph LR
  subgraph ONPREM["On-prem routers"]
    RTRA[Router — site A<br/>ASN 65001]
    RTRB[Router — site B<br/>ASN 65001]
  end

  subgraph AWS["AWS"]
    DXA[DX connection: site_a<br/>100G · MACsec requested]
    DXB[DX connection: site_b<br/>100G · MACsec requested]
    DXGW[Direct Connect Gateway<br/>dxgw-prod]
    TGW[Transit Gateway<br/>tgw-prod · ASN 64513]
    RTPROD[(Route table: prod)]
    RTSHARED[(Route table: shared)]
    RTHYBRID[(Route table: hybrid)]
    MCAST{{Multicast domain<br/>mcast-market-data<br/>static sources}}
    PG[Placement group<br/>pg-feed-handlers · cluster strategy]

    DXA --- DXGW
    DXB --- DXGW
    DXGW --- TGW
    TGW --- RTPROD
    TGW --- RTSHARED
    TGW --- RTHYBRID
    TGW --- MCAST
    MCAST -.->|static source<br/>var.source_eni_id, Nitro only| PG
    MCAST -.->|static members<br/>var.consumer_eni_ids| PG
  end

  RTRA -->|Transit VIF: tvif-site-a<br/>MTU 8500| DXA
  RTRB -->|Transit VIF: tvif-site-b<br/>MTU 8500| DXB
```

Add a second connection at each location, on different devices, to reach
Maximum Resiliency (99.99%) — not encoded in this file or diagram.

---

## `terraform-gcp-platform-baseline.tf`

A regional private GKE Autopilot cluster and an internal-only Cloud Run
service, sharing a CMEK key, with Workload Identity (no exported keys) and
a billing budget with 50/80/100% alert thresholds — the golden path a
workload team consumes as a module in under an hour.

```mermaid
graph TB
  subgraph PROJECT["var.project_id"]
    KMS[(Cloud KMS: ck-app_name<br/>90-day rotation)]
    GKE[GKE Autopilot: gke-app_name-region<br/>REGIONAL · private nodes + endpoint<br/>Binary Authorization enforced]
    WISA[Workload Identity SA<br/>sa-app_name]
    RUNSA[Cloud Run SA<br/>sa-run-app_name]
    RUN[Cloud Run: run-app_name<br/>ingress = INTERNAL_LOAD_BALANCER]
    BUDGET[[Billing budget<br/>50% / 80% / 100% thresholds]]

    KMS -->|database_encryption| GKE
    GKE -->|workload_identity_config| WISA
    RUN --- RUNSA
  end

  subgraph VPC["var.network_self_link"]
    SUBNET[var.subnetwork_self_link]
  end

  GKE --- SUBNET
  RUN -->|Direct VPC egress<br/>ALL_TRAFFIC| SUBNET
  CALLER[Internal caller<br/>var.invoker_members] -->|roles/run.invoker| RUN
```

Terraform provisions the cluster and the service; it deliberately does not
manage what runs inside the cluster — that's GitOps, coupling the two only
makes both slower.

---

## `cli-cheatsheet.md`

Operational commands, organized by "what you actually do at 03:00": circuit
and BGP/BFD state, NCC, connectivity diagnostics, placement and NIC config,
GKE/Cloud Run/Vertex AI posture, path validation (MTU discovery, p50/p95/p99
latency, throughput), microsecond-latency and kernel-scheduling measurement
for HFT workloads, multicast verification, a guardrail/posture sweep, and a
pre-production sanity checklist. No architecture diagram — it's a reference
card, not a topology.

## Deliverable templates

Not architecture examples — starting points for the durable artefacts this
skill produces, following the structure `agents/fsi-cloud-architect.md` and
`references/06-design-review-checklists.md` already specify:

- **`adr-template.md`** — architecture decision record: context, decision,
  options with a 36-month cost comparison, topology, resiliency tier,
  failure modes, build path, consequences.
- **`migration-plan-template.md`** — waves, cutover approach per wave,
  the "connect the minimum" blast-radius discipline
  (`references/11-ma-cloud-integration.md` §4), rollback plan, cost with
  double-running stated honestly, risk register.
- **`design-review-report-template.md`** — findings table by severity,
  full checklist-section coverage log, resiliency-tier verification,
  sign-off — the format `agents/fsi-cloud-architect.md`'s "How to Work a
  Review Task" section specifies.
