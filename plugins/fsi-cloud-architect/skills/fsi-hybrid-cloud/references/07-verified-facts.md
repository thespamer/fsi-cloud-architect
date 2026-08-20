# Verified Facts, Limits and Sources

Every number quoted elsewhere in this skill is recorded here with its source.
**Look a number up here before stating it.** If it is not in this file, say it
needs verification and name where to check.

Verified: **August 2026**. Cloud specifications change; re-verify anything
load-bearing before committing a design.

---

## 1. Google Cloud — Dedicated Interconnect

| Fact | Value |
| --- | --- |
| 10G link bundles | 1 × 10 Gbps up to 8 × 10 Gbps (10–80 Gbps) |
| 100G link bundles | 1 × 100 Gbps up to 8 × 100 Gbps (100–800 Gbps) |
| 400G link bundles | 1 × 400 Gbps up to 8 × 400 Gbps (400–3200 Gbps) |
| VLAN attachment MTU | 1440, 1460, 1500 or 8896 bytes |
| MTU 8896 restriction | Unencrypted IPv4/IPv6 only |
| 99.99% SLA topology | ≥4 connections: 2 in one metro + 2 in another; within each metro, different edge availability domains |
| 99.9% SLA topology | ≥2 connections in the same metro, different edge availability domains |
| MACsec | Supported (separate configuration procedure) |
| On-prem router requirements | LACP, EBGP-4 multi-hop, 802.1Q VLANs |
| Fibre distance limit | 10 km maximum |
| BGP address family | Dual-stack (IPv4+IPv6) or single-stack IPv4; Cloud Router can run IPv4 session, IPv6 session, or both |

Source: [Dedicated Interconnect overview — Google Cloud Documentation](https://docs.cloud.google.com/network-connectivity/docs/interconnect/concepts/dedicated-overview)

---

## 2. Google Cloud — Cross-Cloud Interconnect

| Fact | Value |
| --- | --- |
| Supported remote clouds | AWS, Microsoft Azure, Oracle Cloud Infrastructure, Alibaba Cloud |
| Port speeds — AWS and OCI | 10, 100, 400 Gbps |
| Port speeds — Azure and Alibaba | 10, 100 Gbps |
| 99.99% SLA topology | Two connection pairs across different metros, each using separate edge availability domains |
| 99.9% SLA topology | Primary + redundant connection in different edge availability domains within one metro |
| MTU | Jumbo MTU configurable; remote provider support may differ from Google's |
| Pricing | Fixed port pricing; outbound data transfer on VLAN attachments priced by local (same metro as destination region) vs remote (different metro) |
| **Partner** Cross-Cloud Interconnect | No physical provisioning; provisions in **minutes vs 1–4 weeks**; granular **1–100 Gbps**; built-in resiliency without manual configuration |

Source: [Cross-Cloud Interconnect overview — Google Cloud Documentation](https://docs.cloud.google.com/network-connectivity/docs/interconnect/concepts/cci-overview)

---

## 3. Google Cloud — Networking Announcements, Next '26

| Item | Status |
| --- | --- |
| Cloud Interconnect 400 Gbps circuits, up to 3.2 Tbps in a single connection | GA |
| Partner Cross-Cloud Interconnect for AWS | GA |
| Partner Cross-Cloud Interconnect for AWS in Network Connectivity Center | Preview |
| NCC static routes using internal load balancer as next hop | GA |
| NCC privately-used public IP (PUPI) support | GA |
| Hybrid Subnets | GA |
| NCC Gateway with third-party SSE — Palo Alto Networks | GA soon |
| NCC Gateway with third-party SSE — Symantec | Preview |
| Verified Peering Provider programme | GA, 175+ providers |
| Last-mile site-to-cloud private connectivity in minutes | Preview soon |
| Cloud Number Registry (IPAM) | Preview |
| Post-quantum cryptography support | GA soon |
| Cloud WAN reach | 10M+ km terrestrial and subsea fibre |
| Cross-Cloud Network adoption | 65% of the Fortune 100; up to 27 exabytes/month |

Source: [What's new in cloud networking at Next '26 — Google Cloud Blog](https://cloud.google.com/blog/products/networking/whats-new-in-cloud-networking-at-next26)

---

## 4. AWS — Direct Connect

| Fact | Value |
| --- | --- |
| Dedicated connection speeds | 1, 10, 100, 400 Gbps |
| Hosted connection speeds | 50 Mbps – 25 Gbps |
| MACsec | IEEE 802.1AE on 10, 100 and 400 Gbps connections, at select locations |
| SiteLink | Site-to-site over the AWS backbone; requires connections at two or more DX locations |
| Private VIF MTU | 1500 or 9001 |
| Transit VIF MTU | 1500 or 8500 |
| Mixed-MTU route resolution | 1500 is used |
| Transit gateway jumbo maximum | 8500 |
| MTU change impact | Up to 30 seconds of connectivity disruption across all VIFs on the connection |
| Hosted connection jumbo frames | Only if enabled on the parent hosted connection |

Sources: [AWS Direct Connect features](https://aws.amazon.com/directconnect/features/) · [Set MTU for virtual interfaces](https://docs.aws.amazon.com/directconnect/latest/UserGuide/set-jumbo-frames-vif.html)

### Direct Connect resiliency models and SLA

| Model | Topology | SLA target |
| --- | --- | --- |
| Maximum Resiliency (Multi-Site Redundant) | Separate connections on separate devices across multiple locations, redundant hardware per site | 99.99% |
| High Resiliency (Multi-Site Non-Redundant) | One connection at each of multiple locations | 99.9% |
| Single-Site Redundant | ≥2 connections on different devices at one location | Not recommended for production |
| Single Connection | One connection | 92.5% |

**Service credits**

| Deployment | 10% credit | 25% credit | 100% credit |
| --- | --- | --- | --- |
| Multi-Site Redundant | < 99.99% | < 99.0% | < 95.0% |
| Multi-Site Non-Redundant | < 99.9% | < 99.0% | < 95.0% |
| Single Connection | < 92.5% | < 90.0% | — |

AWS statement: "For production workloads, AWS does not recommend using any
Deployment other than a Multi-Site Redundant Deployment or a Multi-Site
Non-Redundant Deployment."

Sources: [AWS Direct Connect Resiliency Recommendations](https://aws.amazon.com/directconnect/resiliency-recommendation/) · [AWS Direct Connect SLA](https://aws.amazon.com/directconnect/sla/)

---

## 5. AWS Interconnect (GA 14 April 2026)

| Variant | Detail |
| --- | --- |
| **Interconnect – Multicloud** | Layer 3 private connections between AWS and other clouds; traffic stays on provider backbones, never the public internet; MACsec enabled by default; redundant facilities built in. **Google Cloud available now; Azure and OCI later in 2026** |
| **Interconnect – Last Mile** | Connects on-premises and branch locations via participating providers. **Automatically provisions four redundant connections across two physical locations**, configures BGP, and enables **MACsec and jumbo frames by default**. 1–100 Gbps, adjustable in console |
| Last-mile partners | Lumen Technologies (launch, April 2026); AT&T and Megaport in progress |
| Attachment model | Interconnect attachments connect to Direct Connect Gateways, which link to Virtual Private Gateways, Transit Gateways or AWS Cloud WAN |

Sources: [AWS Interconnect is now generally available — AWS News Blog](https://aws.amazon.com/blogs/aws/aws-interconnect-is-now-generally-available-with-a-new-option-to-simplify-last-mile-connectivity/) · [Selecting the right AWS private connectivity options: a decision framework](https://aws.amazon.com/blogs/networking-and-content-delivery/selecting-the-right-aws-private-connectivity-options-a-decision-framework/)

---

## 5a. BFD — Both Clouds

### Google Cloud Router

| Parameter | Range | Default |
| --- | --- | --- |
| BFD minimum transmit interval | 1000–30,000 ms | 1000 ms |
| BFD minimum receive interval | 1000–30,000 ms | 1000 ms |
| BFD multiplier | 5–16 packets | 5 |
| Session initialization mode | Active / Passive / Disabled | **Disabled** |

**Supported only on** VLAN attachments for Dedicated Interconnect and Partner
Interconnect, **and only with Dataplane version 2**.
**Not supported on** HA VPN tunnels or router appliance (Network Connectivity
Center) spokes.

Source: [Bidirectional Forwarding Detection (BFD) overview — Cloud Router](https://docs.cloud.google.com/network-connectivity/docs/router/concepts/bfd)

### AWS Direct Connect

| Fact | Value |
| --- | --- |
| Support | Asynchronous BFD is **automatically enabled for each Direct Connect virtual interface** |
| Activation | **Does not take effect until configured on your router** |
| AWS-side liveness detection minimum interval | 300 |
| AWS-side liveness detection multiplier | 3 |

Source: [AWS Direct Connect FAQs](https://aws.amazon.com/directconnect/faqs/)

---

## 6. AWS Transit Gateway Multicast

| Fact | Value |
| --- | --- |
| Dynamic membership | IGMPv2, **IPv4 only** |
| Static configuration | API-based static sources and group members, **IPv4 and IPv6** |
| Nitro instances | Can be senders and receivers |
| Non-Nitro instances | **Receivers only** |
| Multicast domains per subnet | 1 |
| **Not supported over** | Direct Connect, Site-to-Site VPN, peering attachments, Transit Gateway Connect attachments |
| Fragmentation | Not supported — fragmented packets are dropped |
| IGMP query interval | Every 2 minutes |
| Failed queries before member removal | 3 consecutive |
| Post-outage traffic window | 7 minutes (420 seconds) |
| Query retention after failure | 12 hours |
| Quotas | See the Transit Gateway quotas page — domain, group, member and source limits are not reproduced here |

Source: [Multicast in AWS Transit Gateway — Amazon VPC documentation](https://docs.aws.amazon.com/vpc/latest/tgw/tgw-multicast-overview.html)

### CME MDP multicast reference pattern

- GRE tunnel between on-prem virtual router and a transit-VPC virtual router,
  with PIM neighbour relationships
- Transit Gateway **does not transparently transmit IGMP join messages** — static
  IGMP joins required on the cloud-side router (`ip igmp static-group <group>`)
- Multicast domain created with **static sources support enabled** and IGMPv2
  disabled
- Source/destination checks must be **disabled** on all router interfaces carrying
  transit traffic
- AWS has a Direct Connect location in the CyrusOne Aurora, Illinois facility
  (CME's data centre)
- Stated prerequisite: 300-level knowledge of multicast, GRE, PIM and OSPF

Source: [CME Group MDP multicast data access on AWS using Transit Gateway — AWS for Industries](https://aws.amazon.com/blogs/industries/cme-group-mdp-multicast-data-access-on-aws-using-transit-gateway/)

---

## 7. Latency Measurements

### AWS instance-to-instance RTT (tuned)

| Instance | p50 | p99.9 |
| --- | --- | --- |
| `m8azn.metal` | 17.7 µs | 19.4 µs |
| `m5zn.metal` | 20.3 µs | 22.2 µs |
| `c7i.24xl` metal | 20.3 µs | 22.0 µs |
| `c8g` (Graviton) | 21.4 µs | 23.4 µs |

- Metal tail-latency advantage over full-slot variants: **3.3–10.9 µs (15–29%)
  at p99.9**
- OS tuning (kernel 6.1+) gave **28–36% p50 improvement** on `c7i` and `m5zn`;
  **~1%** on `m8azn`
- **ENA Express is not recommended for HFT** — can modestly inflate p50 baseline;
  prefer DPDK or XDP zero-copy
- Cluster Placement Group with VPC peering described as the lowest-latency
  arrangement
- Recommendation to select the **largest instance size in a family** for exclusive
  host access
- PTP error bound typically **under 40 µs**; NTP typically **under 100 µs**
- Instance store: sub-millisecond, ephemeral; io2 Block Express for durability

### Latency hierarchy (orders of magnitude available per layer)

| Layer | Magnitude |
| --- | --- |
| Placement and region | 100 ms |
| Network path | 2 ms |
| Instance selection | 200 µs |
| OS tuning and kernel bypass | 50 µs |
| Application tuning | 5 µs |

Source: [Optimize tick-to-trade latency for digital assets exchanges and trading platforms on AWS: Part 2](https://aws.amazon.com/blogs/web3/optimize-tick-to-trade-latency-for-digital-assets-exchanges-and-trading-platforms-on-aws-part-2/)

### GCP C4 benchmark

| Metric | Value |
| --- | --- |
| p50 RTT | 15 µs |
| p99 RTT | 22 µs |
| In-process | sub-1.5 µs |
| Improvement over C3 | up to 40% reduction in median RTT |
| Consistency | stable across 48, 96 and 192 vCPU shapes, and across 1×–100× market replay speeds |
| Tuning applied | kernel bypass, hardware offloading, ring buffering, core pinning, vNUMA alignment, P-state and C-state tuning, core isolation |

Source: [C4 tick-to-trade benchmarking — 28Stone](https://www.28stone.com/news/c4-tick-to-trade-benchmarking/)

---

## 8. Time Synchronisation

### MiFID II RTS 25

**Trading venue operators**

| Gateway-to-gateway latency | Max divergence from UTC | Granularity |
| --- | --- | --- |
| > 1 ms | 1 ms | 1 ms or better |
| < 1 ms | 100 µs | 1 µs or better |

**Members and participants of trading venues**

| Activity | Max divergence from UTC | Granularity |
| --- | --- | --- |
| High-frequency algorithmic trading | 100 µs | 1 µs or better |
| Voice trading systems | 1 s | 1 s or better |
| RFQ systems with human intervention | 1 s | 1 s or better |
| Negotiated transactions | 1 s | 1 s or better |
| Any other trading activity | 1 ms | 1 ms or better |

Clocks must synchronise to UTC issued and maintained by the timing centres listed
in the latest BIPM Annual Report on Time Activities.

Source: [Time-stamping and business clocks synchronisation under MiFID II](https://www.emissions-euets.com/time-stamping-and-business-clocks-synchronisation)

### AWS Amazon Time Sync

| Fact | Value |
| --- | --- |
| Precision tiers | Microsecond-accurate time; nanosecond-precision hardware packet timestamps |
| Precision Time Placement Group (PTPG) | Placement strategy for launching instances with the PTP hardware clock (PHC) enabled |
| June 2026 expansion | Microsecond-accurate time on 26 additional EC2 instance types, all commercial regions |
| Foundation | Reference clocks in Nitro hardware |

Sources: [Amazon Time Sync Service adds support for microsecond accurate time on 26 additional EC2 instance types](https://aws.amazon.com/about-aws/whats-new/2026/06/ec2-time-sync-precision-time-placement-group/) · [Amazon Time Sync now supports nanosecond hardware packet timestamps](https://aws.amazon.com/about-aws/whats-new/2025/06/amazon-time-sync-nanosecond-hardware-packet-timestamps/)

---

## 9. GCP Placement Policies

| Fact | Value |
| --- | --- |
| Compact placement | Places instances close together within a zone to reduce inter-instance latency; **best-effort**, depends on machine type and zone capacity |
| Maximum distance values | Lower values give tighter placement but fewer available machines |
| Spread placement | Distributes across separate hardware for reliability (HDFS, Cassandra, Kafka) |
| Scope | Zone level |
| Exception | For A3 High with 8 GPUs, and H4D in managed instance groups, use **workload policies** instead |

Source: [Placement policies overview — Google Cloud Documentation](https://docs.cloud.google.com/compute/docs/instances/placement-policies-overview)

---

## 10. FactSet-Published Market-Data-in-Cloud Findings

Useful because they are the firm's own stated positions.

| Finding | Detail |
| --- | --- |
| Cloud-resident latency expectation | Applications based entirely in the cloud should expect **10–50 ms** |
| Shared infrastructure | Can cause variations in performance versus dedicated on-prem systems |
| Cost structure | Cloud environments with egress to on-premises applications can drive higher operating costs; providers charge based on message volume |
| Ticker plant | Migrated to AWS on EC2 Nitro instances — described as the first global ticker plant deployed entirely in the cloud (announced 2020, completion targeted 2021) |
| Graviton efficiency | `c7g.large` used **just over half the CPU** of the incumbent `c5n` at **identical latency**. Single consumer: 10% CPU on `c7g.large` vs 20% on `c5n` |
| No latency penalty | **No latency increases** observed across the instance families tested (`c5n`, `c6in`, `c6gn`, `c7g`) |
| Metrics caveat | CloudWatch CPU metrics include hypervisor system time that `sar` does not capture; multi-vCPU instances incur additional hypervisor overhead and context switching |
| Scaling caveat | Performance does not double when doubling CPUs |

Sources: [FactSet and AWS announce plans to bring FactSet's global exchange data to the cloud](https://investor.factset.com/news-releases/news-release-details/factset-and-aws-announce-plans-bring-factsets-global-exchange) · [Real-Time Market Data in the Public Cloud — FactSet Insight](https://insight.factset.com/real-time-market-data-in-the-public-cloud-adapting-to-new-business-models-amid-legacy-challenges) · [Market Data in the Cloud — FactSet on Medium](https://medium.com/factset/market-data-in-the-cloud-65eb4889e8f5)

---

## 11. GenAI and AI/ML Platform

### Cloud Run GPUs

| Fact | Value |
| --- | --- |
| GPU type | NVIDIA L4 |
| Status | **GA since 2 June 2025** |
| Quota | No quota request required |
| Scale to zero | Yes — GPU instances scale to zero when idle |
| Cold start | **Under 5 seconds** from zero to an instance with GPU and drivers |
| Time to first token (example) | ~19 s for `gemma3:4b`, including startup and model load |
| Billing | Pay per second |
| Redundancy | Zonal redundancy by default with SLA coverage; a lower-priced best-effort failover option exists |
| Regions at GA | us-central1, europe-west1, europe-west4, asia-southeast1, asia-south1 (more since — verify current list) |

Source: [Cloud Run GPUs are now generally available — Google Cloud Blog](https://cloud.google.com/blog/products/serverless/cloud-run-gpus-are-now-generally-available)

### GKE Inference Gateway

Routes LLM requests by model and by **KV-cache state** rather than round-robin.
Three functions: model-aware routing to the correct backend pool; prefix-cache
routing that hashes token prefixes and sends requests to replicas already holding
them; and capacity-based balancing toward replicas with the most free KV cache.

Measured on 1,000 requests sharing a 4,096-token system prompt across 8 replicas:

| Metric | Round-robin | KV-cache-aware |
| --- | --- | --- |
| TTFT p50 | 3.1 s | 0.38 s |
| TTFT p95 | 4.9 s | 0.71 s |
| Throughput | 840 tokens/s | 2,620 tokens/s |
| GPU prefill waste | ~88% | ~12% |

**Effective throughput improved 3.1×.** The routing engine (llm-d Endpoint
Picker) polls replica Prometheus metrics every 100 ms and decides in under 2 ms
per request; the logic is open source and runs on any Kubernetes cluster.

Source: [GKE Inference Gateway: KV-cache-aware LLM routing explained](https://www.spheron.network/blog/gke-inference-gateway-kv-cache-aware-llm-routing/)

Related, from Next '26 (see §3): GKE Inference Gateway disaggregated serving for
vLLM/SGLang is **GA**; multi-region support and predictive latency boost are in
**preview**.

### VPC Service Controls with Vertex AI

**Protects:** batch and online inference, custom training (control and data
planes), Vertex AI Pipelines, Vector Search, Feature Store, generative AI models,
managed training clusters, Vertex AI Agent Engine.

**Limitations that affect design:**

- VPC-SC blocks public internet access by default; authorised external users need
  an access-level allowlist
- Custom pipeline components **cannot install packages from public PyPI** — an
  internal mirror is required
- Endpoints must be created **after** the project joins the perimeter
- Agents must be deployed **after** perimeter enrolment
- **Model Garden public endpoint deployments are not supported**
- PSC interface + VPC-SC requires a proxy inside the perimeter on an RFC 1918
  subnet, plus a Cloud NAT gateway for egress
- Services such as Vertex AI Pipelines require "VPC Service Controls for
  peerings" enabled, which alters producer routing and creates Cloud DNS-managed
  private zones
- Data labelling requires labeller IP addresses on the access level

Source: [VPC Service Controls with Vertex AI — Google Cloud Documentation](https://docs.cloud.google.com/vertex-ai/docs/general/vpc-service-controls)

### Private inference endpoints

Google documents **dedicated private endpoints based on Private Service Connect**
as the recommended approach for Vertex AI online inference: dedicated rather than
shared connectivity, no public IP exposure, traffic over Google's internal
network. Preferred over private services access / VPC peering for reduced
network contention and lower operational complexity.

On AWS, **SageMaker Unified Studio added AWS PrivateLink support in January
2026**; Bedrock and SageMaker are reachable over VPC interface endpoints.

Sources: [Dedicated private endpoints with Private Service Connect for online inference](https://docs.cloud.google.com/vertex-ai/docs/predictions/private-service-connect) · [Amazon SageMaker Unified Studio now supports AWS PrivateLink](https://aws.amazon.com/about-aws/whats-new/2026/01/amazon-sagemaker-unified-studio-aws-privatelink)

---

## 12. EU AI Act — Revised Timeline

A provisional political agreement on the **Omnibus** package was reached on
**6 May 2026**, postponing the high-risk deadlines and replacing the proposed
conditional trigger mechanism with fixed dates. Formal adoption and Official
Journal publication were expected ahead of 2 August 2026.

| Obligation | Original date | Revised date |
| --- | --- | --- |
| **Transparency obligations (Art. 50)** | 2 August 2026 | **Unchanged — 2 August 2026** |
| Watermarking grace period | — | to **2 December 2026** |
| **High-risk, Annex III (stand-alone)** | 2 August 2026 | **2 December 2027** (~16-month delay) |
| **High-risk, Annex I (embedded in regulated products)** | 2 August 2027 | **2 August 2028** (~12-month delay) |
| Regulatory sandbox establishment | 2 August 2026 | 2 August 2027 |

**2 August 2026 remains an active compliance date** for the transparency
provisions.

Source: [EU AI Act Omnibus Agreement — Postponed High-Risk Deadlines and Other Key Changes, Gibson Dunn](https://www.gibsondunn.com/eu-ai-act-omnibus-agreement-postponed-high-risk-deadlines-and-other-key-changes/)

---

## 13. Disaster Recovery — Google Cloud Guidance

### Tiering (Google's stated enterprise distribution)

| Tier | Share of estate | Requirement |
| --- | --- | --- |
| Tier 1 | ~5% | Global customer-facing; zero RTO/RPO |
| Tier 2 | ~35% | Regional; 15-minute to 1-hour windows |
| Tier 3 | ~60% | Internal; 1–12 hour recovery windows |

### Principles stated

- **RPO of zero demands synchronous replication**, which restricts the viable
  product set. Higher RPO tolerance enables asynchronous approaches and widens
  the options.
- **RTO near zero requires continuously running hot standby** across regions —
  expensive and complex. Most applications target 1–24 hour RTO with warm
  standby and automated scale-up.
- Multi-region outage is "extremely rare; most organizations accept this risk
  level".
- **Avoid dependency on management-plane operations during critical business
  processes.**
- Test failover procedures regularly.

### Service capability

| Resilience | Handled by | Compose it yourself |
| --- | --- | --- |
| **Zone** | GKE regional clusters, Cloud SQL HA configuration, Spanner, Cloud Storage, Cloud Load Balancing | Compute Engine (zonal) — MIGs across zones behind a load balancer |
| **Region** | Spanner multi-region, multi-region Cloud Storage | GKE multi-region, Cloud Load Balancing with manual failover (typically DNS reconfiguration) |
| **Limited DR capability** | — | Compute Engine (zonal), Dataflow (stateless but must restart), BigQuery (regional; no multi-region replication) |

Source: [Architecting disaster recovery for cloud infrastructure outages — Google Cloud Architecture Center](https://docs.cloud.google.com/architecture/disaster-recovery)

---

## 14. Things Deliberately Not Recorded Here

These change too often or are too account-specific to state safely. Look them up
live, in the provider console or documentation, every time:

- Current pricing for any service, in any region
- Per-region service availability and quota defaults
- Transit Gateway multicast numeric quotas
- Interconnect and Direct Connect facility lists
- Instance type availability by region
- Current preview-vs-GA status of any feature listed as "preview" above
- Exchange market data fee schedules and licensing terms
- Current text of any regulation
- Cloud Run GPU region list (expanding) and available GPU types
- Vertex AI model availability and per-model quotas
- Whether the EU AI Act Omnibus text was formally adopted as agreed — confirm
  against the Official Journal before relying on the revised dates
