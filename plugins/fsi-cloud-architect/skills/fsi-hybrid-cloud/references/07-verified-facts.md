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

## 14. Private Service Connect and AWS PrivateLink

**Private Service Connect (PSC), Google Cloud.** A consumer creates a PSC
endpoint (a forwarding rule that gets an internal IP in the consumer's own VPC)
that attaches to a service attachment published by a producer. Traffic stays on
Google's network. No VPC peering, so none of peering's transitive-routing or
CIDR-overlap limitations apply. The producer side is fronted by an internal
passthrough Network Load Balancer and needs a dedicated NAT subnet. PSC also
covers **Private Service Connect for Google APIs** (reaching Google/Cloud APIs
through an internal IP instead of the public API endpoint) and **Private
Service Connect interfaces** (the reverse direction: letting a published
service reach into a consumer's VPC).

Source: [Private Service Connect overview — Google Cloud](https://docs.cloud.google.com/vpc/docs/private-service-connect) ·
[Access published services through endpoints — Google Cloud](https://docs.cloud.google.com/vpc/docs/configure-private-service-connect-services)

**AWS PrivateLink.** A provider publishes a VPC endpoint service backed by a
Network Load Balancer or a Gateway Load Balancer. A consumer creates an
interface endpoint — an ENI with a private IP — in their own VPC/subnet, or a
gateway endpoint (S3/DynamoDB only, no ENI, routed via a prefix-list route).
Traffic stays on the AWS network; nothing is exposed to the public internet or
requires VPC peering.

**AWS PrivateLink now supports native cross-region connectivity** (announced
26 November 2024): an interface endpoint can reach a VPC endpoint service in a
different AWS Region within the same partition, without cross-region peering
or transiting the public internet. At launch this covered a specific set of
regions (US East N. Virginia, US West Oregon, Europe Ireland, Asia Pacific
Singapore, South America São Paulo, Asia Pacific Tokyo, Asia Pacific Sydney) —
confirm current regional coverage before designing against it.

Source: [AWS PrivateLink now supports cross-Region connectivity — AWS What's New](https://aws.amazon.com/about-aws/whats-new/2024/11/aws-privatelink-across-region-connectivity) ·
[Share your services through AWS PrivateLink — AWS documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/privatelink-share-your-services.html)

**When to reach for PSC/PrivateLink rather than peering, Interconnect or a
transit hub:** the requirement is "let this one specific service be consumed
privately," not "join these two networks." Typical FSI cases — a market-data
or reference-data API published to a subsidiary, an acquired entity, or a
partner without giving them a route into the wider VPC; consuming a SaaS
vendor's endpoint privately (many vendors now publish a PrivateLink/PSC
front door precisely so customers avoid the public internet); one business
unit's platform team publishing a shared service (secrets, feature store,
model endpoint) to every other BU without a mesh of peering connections.

See `references/08-genai-ml-platform.md` §2 for the private-inference-specific
case (Vertex AI dedicated PSC endpoints, Bedrock/SageMaker PrivateLink
interface endpoints) — that is a live application of this pattern, not a
separate mechanism.

---

## 15. Load Balancing — Google Cloud and AWS

**Google Cloud's current load balancer family** (2026 naming) splits along two
axes — layer (Application vs Network) and scope (global vs regional, external
vs internal):

| Family | Variant | Scope | Protocols |
| --- | --- | --- | --- |
| Application Load Balancer | Global external | Global | HTTP/HTTPS |
| Application Load Balancer | Regional external | Regional | HTTP/HTTPS |
| Application Load Balancer | Regional internal | Regional | HTTP/HTTPS |
| Application Load Balancer | Cross-region internal | Multi-region | HTTP/HTTPS |
| Proxy Network Load Balancer | Global external | Global | TCP, optional SSL offload |
| Proxy Network Load Balancer | Regional external / internal | Regional | TCP |
| Passthrough Network Load Balancer | Global external | Global (Preview) | TCP, UDP, ESP, GRE, ICMP, ICMPv6 |
| Passthrough Network Load Balancer | Regional external | Regional | TCP, UDP, ESP, GRE, ICMP, ICMPv6 |
| Passthrough Network Load Balancer | Internal | Regional only | TCP, UDP, ICMP, ICMPv6, SCTP, ESP, AH, GRE |

The naming is the thing that trips people up coming from AWS: "Network Load
Balancer" on GCP has two different products (proxy vs passthrough) with
different protocol support, and "Application Load Balancer" is always Layer 7
regardless of global/regional scope. The **ILB** engineers usually mean in
casual conversation is the **internal passthrough Network Load Balancer** —
the zonal/regional building block behind most private service-to-service
traffic, and the one that sits behind a PSC service attachment (§14).

Source: [Choose a load balancer — Google Cloud Load Balancing documentation](https://docs.cloud.google.com/load-balancing/docs/choosing-load-balancer)

**AWS's current load balancer family** (Elastic Load Balancing):

| Type | Layer | Typical FSI use |
| --- | --- | --- |
| **Application Load Balancer (ALB)** | 7 (HTTP/HTTPS/gRPC) | Path/host-based routing, WAF integration, mTLS termination — the default for web and API front doors |
| **Network Load Balancer (NLB)** | 4 (TCP/UDP/TLS) | Ultra-low latency, static IP per AZ, millions of requests/second, the load balancer PrivateLink/VPC endpoint services are built on |
| **Gateway Load Balancer (GWLB)** | 3 (GENEVE encapsulation) | Transparent insertion of third-party appliances (firewalls, IDS/IPS) in-path, including as the target behind a Gateway Load Balancer endpoint |

**Decision rule that resolves most arguments:** if the requirement is
HTTP-layer routing, WAF, or content-based rules, use ALB. If the requirement is
raw TCP/UDP performance, a static IP, or the load balancer is the thing a
VPC endpoint service will attach to, use NLB. GWLB is a narrow, specific
case — inline traffic inspection — not a general-purpose choice.

Source: [Elastic Load Balancing features — AWS documentation](https://docs.aws.amazon.com/elasticloadbalancing/latest/userguide/elastic-load-balancing.html) ·
[Access an inspection system using a Gateway Load Balancer endpoint — AWS documentation](https://docs.aws.amazon.com/vpc/latest/privatelink/gateway-load-balancer-endpoints.html)

---

## 16. PCI DSS — Provider Responsibility Highlights

**Google Cloud PCI DSS v4.0.1 shared-responsibility matrix**: Google takes
sole responsibility for firewall-configuration security of underlying
infrastructure, default anti-spoofing, malware protection for GCP's own
infrastructure, and default at-rest encryption for customer data. Named
services mapped to requirements: Cloud KMS/Cloud HSM (key management), Cloud
DLP (PAN discovery/masking), Secret Manager, Network Intelligence Center
(network diagram/data-flow documentation), Security Command Center Premium
(malware/threat detection), Shielded VMs, VPC Service Controls.

Source: [Google Cloud PCI DSS v4.0.1 Shared Responsibility Matrix](https://services.google.com/fh/files/misc/gcp_pci_dss_v4_responsibility_matrix.pdf)

**AWS** completes a Level 1 PCI DSS assessment as a Service Provider **twice a
year**, publishing its AoC through AWS Artifact. Named services: CloudHSM
(FIPS 140-2 Level 3 HSM), **AWS Payment Cryptography** (managed HSM
specifically for PIN generation/translation/verification —
`GeneratePinData`/`TranslatePinData` APIs — distinct from general-purpose
KMS/CloudHSM), Security Groups/NACLs/Network Firewall (segmentation),
GuardDuty Malware Protection, Macie (sensitive-data discovery), AWS Config
(configuration drift), CloudTrail (API audit trail).

Source: [PCI DSS v4.0 Compliance on AWS whitepaper](https://d1.awsstatic.com/whitepapers/compliance/pci-dss-compliance-on-aws-v4-102023.pdf) ·
[AWS Payment Cryptography — TranslatePinData API reference](https://docs.aws.amazon.com/payment-cryptography/latest/DataAPIReference/API_TranslatePinData.html)

---

## 17. Open Finance Brasil — FAPI Security Profile

Mandates: PS256 for JWS signing, RSA-OAEP with A256GCM for JWE encryption on
sensitive messages; authorization servers must accept signed+encrypted JWE
request objects or require Pushed Authorization Requests (PAR); TLS 1.2+
restricted to `TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256` and
`TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384` with session resumption/renegotiation
disabled; two authentication levels (LoA2 single-factor, LoA3
multi-factor); Dynamic Client Registration per RFC 7591/7592 with keys
registered via `jwks_uri`; access tokens expire in 300–900 seconds; CPF/CNPJ
claims for identity binding.

Source: [Open Finance Brasil Financial-grade API Security Profile 1.0](https://openfinancebrasil.atlassian.net/wiki/spaces/OF/pages/240649123) ·
[Open Finance Brasil Dynamic Client Registration](https://openfinancebrasil.atlassian.net/wiki/spaces/OF/pages/1334116474)

---

## 18. UK Open Banking — Governance in Transition

The Open Banking Implementation Entity (OBIE) has been succeeded by **Open
Banking Limited**. As of early 2026 a "Future Entity" restructuring process
is under way to establish the long-term central standard-setting body —
**this is actively changing; confirm current governance before naming a
specific authority in a client-facing document.**

Source: [Open banking – process to establish a Future Entity — Global Regulation Tomorrow, Jan 2026](https://www.regulationtomorrow.com/2026/01/open-banking-process-to-establish-a-future-entity/)

---

## 19. Banking-as-a-Service Ledger Precedents

**Google Cloud Spanner (Current, a US challenger bank — published 6 Dec
2024):** migrated its core member/account/wallet/gateway graph service to
Spanner for consistent writes, horizontal scale, low read latency and
multi-region failover. Results: **zero availability incidents since
migration**, close to **5,000 transactions/second**, **RTO and RPO both
reduced more than 10×** (RTO now ~1 hour), zero-downtime/zero-data-loss
phased cutover (migrate reads → verify → migrate writes).

Source: [How Current leveraged Spanner to build a resilient platform for banking services — Google Cloud Blog](https://cloud.google.com/blog/products/databases/current-challenger-bank-database-resilience-spanner/)

**AWS Amazon QLDB (Quantum Ledger Database) was discontinued** (announced
July 2024). AWS's published migration path for ledger/audit-trail workloads
is **Amazon Aurora PostgreSQL** with cryptographic verification patterns
layered on top. Do not design a new AWS ledger around QLDB.

Source: [Migrate an Amazon QLDB Ledger to Amazon Aurora PostgreSQL — AWS Database Blog](https://aws.amazon.com/pt/blogs/database/migrate-an-amazon-qldb-ledger-to-amazon-aurora-postgresql/)

---

## 20. AWS ENA Express — Published Performance Numbers

ENA Express (built on the Scalable Reliable Datagram / SRD protocol) claims,
per AWS: up to **93% reduction in P99.9 traffic-flow latency** and up to
**400% increase in single-flow throughput**. A cited in-memory-database
benchmark showed **60× improvement at P100 for SET operations** and **>100×
at P100 for GET operations**. These are tail-latency-under-load and
throughput numbers for bulk/bursty flows — not a p50 latency claim for small
messages. See `03-low-latency-market-data.md` §4 for why this makes ENA
Express the wrong tool for an HFT hot path despite the impressive headline
numbers.

Source: [Using ENA Express to improve workload performance on AWS — AWS Networking & Content Delivery Blog](https://aws.amazon.com/blogs/networking-and-content-delivery/using-ena-express-to-improve-workload-performance-on-aws/)

---

## 21. Things Deliberately Not Recorded Here

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
- **PSC and PrivateLink numeric quotas** (endpoints per VPC/region, service
  attachments per producer, connections per endpoint) — these are configurable
  quotas that change per project/account; check the console, not this file
- **Current AWS regions with PrivateLink cross-region support** — the launch
  region list above will have grown
- **The current UK Open Banking governance authority** — the "Future Entity"
  process was ongoing as of this writing; confirm which body is authoritative
- **Exchange colocation facility rosters and cloud on-ramp presence** (§25) —
  named as long-standing orientation anchors, not a verified current
  cross-connect price/availability list
- **Any US open banking / CFPB Rule 1033 compliance date** — this area is
  moving fastest of any regime covered here
- **PCI DSS assessor-specific interpretations** of segmentation adequacy —
  QSAs vary; confirm with the assigned assessor before finalizing a design
- **Which regions currently support AWS Payment Cryptography** — confirm
  against the service's current region list before scoping a design

---

## 22. GCP Bare Metal Machine Series

**Correction to a claim this file used to imply:** GCP is not limited to
Bare Metal Solution (the Oracle-specific colocated appliance). Compute Engine
ships genuine bare-metal machine types — direct, non-hypervisor-mediated
access to host CPU and memory — across six series:

| Series | Machine types | vCPU / memory | Network | Processor |
| --- | --- | --- | --- | --- |
| **C3** | `c3-{highcpu,standard,highmem}-192-metal` | up to 192 vCPU, 1,536 GB | 100 Gbps standard / 200 Gbps Tier_1 | 4th-gen Intel Xeon (Sapphire Rapids) |
| **C4** | standard / highmem variants | up to 288 vCPU, 2,232 GB, 18 TiB local Titanium SSD | 100 Gbps standard / 200 Gbps Tier_1 | 6th-gen Intel Xeon (Granite Rapids) |
| **C4A** | `c4a-{standard,highmem}-96-metal` | 96 vCPU, 384–768 GB | 50 Gbps standard / 100 Gbps Tier_1 | Google Axion (Arm Neoverse V2) |
| **C4D** | highcpu / standard / highmem | up to 384 vCPU, 3,072 GB | 100 Gbps standard / 200 Gbps Tier_1 | 5th-gen AMD EPYC (Turin) |
| **X4** (memory-optimized) | multiple | up to 1,920 vCPU, 32,768 GB | up to 100 Gbps | 4th-gen Intel Xeon |
| **Z3** (storage-optimized) | `z3-highmem-192-highlssd-metal` | 192 vCPU, 1,536 GB, 72,000 GiB Titanium SSD | 100 Gbps standard / 200 Gbps Tier_1 | — |

C4A-metal — Google's first Arm bare-metal type — reached GA **28 May 2026**.
Google's own framing for bare metal names "real-time financial systems"
explicitly as a target workload, alongside third-party hypervisors and
security/CI use cases.

This directly supersedes the AWS-only "choose the largest size / bare metal
wins on the tail" guidance in `03-low-latency-market-data.md` §2–3: the same
lever exists on GCP, across x86 (C3/C4/C4D/X4/Z3) and Arm (C4A).

Source: [Bare metal instances — Google Cloud documentation](https://docs.cloud.google.com/compute/docs/instances/bare-metal-instances) ·
[New Axion C4A metal offers bare-metal performance on Arm — Google Cloud Blog](https://cloud.google.com/blog/products/compute/new-axion-c4a-metal-offers-bare-metal-performance-on-arm) ·
[Compute Engine C3 bare-metal and X4 machine types now GA — Google Cloud Blog](https://cloud.google.com/blog/products/compute/compute-engine-c3-bare-metal-and-x4-machine-types-now-ga)

**Not yet found published:** an instance-to-instance RTT benchmark for GCP
bare metal (C3/C4/C4A/C4D metal) in the style of the AWS `.metal` table in
§7 or the GCP C4 *virtualized* benchmark in the same section. Treat the
AWS metal tail-latency advantage (3.3–10.9 µs / 15–29% at p99.9, §7) as
suggestive, not as a number to quote for GCP metal — this needs the same
tuned instance-to-instance test run on GCP before it goes in a design.

---

## 23. FPGA-Accelerated Instances — AWS F1/F2, and the GCP/Azure Gap

**AWS EC2 F1.** Combines x86 CPUs with Xilinx (now AMD) Virtex UltraScale+
FPGAs, programmed with custom hardware accelerators. Still supported with
its developer toolchain, but AWS's own newer generation is F2 — treat F1 as
legacy for a new design.

**AWS EC2 F2**, GA **12 December 2024** (a smaller `f2.6xlarge` size GA
**5 February 2025**):

| Fact | Value |
| --- | --- |
| FPGAs | Up to 8× AMD Virtex UltraScale+ HBM VU47P (16 GB HBM each, up to 460 GB/s bandwidth) |
| FPGA logic | 2.85M system logic cells, 9,024 DSP slices per FPGA — up to 28 TOPS INT8 |
| Host CPU | 3rd-gen AMD EPYC (Milan), up to 192 vCPU |
| Memory | up to 2 TiB |
| Network | up to 100 Gbps |
| Local storage | up to 2× 7.6 TiB NVMe |
| Smallest size | `f2.6xlarge` — 1 FPGA, 24 vCPU, 256 GB, 950 GB NVMe, 12.5 Gbps |

F2's stated use cases are genomics, media processing, big-data and
network-security acceleration — not exchange connectivity out of the box;
an HFT team would still be writing its own tick-to-trade FPGA image.

**Neither Google Cloud nor Azure publishes a general-purpose FPGA IaaS
instance today.** No GCP FPGA machine type exists in Compute Engine's
catalogue as of this writing. Practical consequence for a GCP-first design:
**FPGA-in-path for market data or order routing on GCP means colocation**,
not a Compute Engine instance type — reinforcing the "sub-10 µs / FPGA
remains colo territory" position in `03-low-latency-market-data.md` §2. If
the workload can tolerate AWS-only for the FPGA tier specifically, F2 is an
option; otherwise budget for a colo FPGA appliance (§24) regardless of
primary cloud.

Sources: [Amazon EC2 F2 instances](https://aws.amazon.com/ec2/instance-types/f2/) ·
[Amazon EC2 F2 instances, featuring up to 8 FPGAs, are generally available — AWS What's New](https://aws.amazon.com/about-aws/whats-new/2024/12/amazon-ec2-f2-instances-8-fpgas/) ·
[Amazon EC2 F2.6xlarge, a new F2 instance size — AWS What's New](https://aws.amazon.com/about-aws/whats-new/2025/02/amazon-ec2-f2-6xlarge-new-f2-instance-size)

---

## 24. Low-Latency Layer-1/Layer-2 Hardware — NICs and Switches

The feed-handler NIC and the cross-connect switch that matter for colo
deployments, named specifically because "kernel bypass" and "low-latency
switch" get proposed generically without naming the actual product:

**NICs — AMD (Solarflare/Xilinx) X2/X3 series.** The de facto standard NIC
in electronic trading environments. `X2522` (10/25 GbE) is the established
low-latency card; `X3522` is AMD's newer part, claimed **~27% lower latency**
than the X2522 on typical trading workloads. Both pair with **OpenOnload**
(Onload) — an open-source, user-space network stack (`Xilinx-CNS/onload` on
GitHub) that intercepts socket calls to bypass the kernel network stack
transparently, i.e. without rewriting the application to a DPDK-style API.
Sits alongside, not in place of, the DPDK/XDP guidance in §4 below — Onload
is the socket-transparent option; DPDK/XDP are the rewrite-the-datapath
option.

**Layer-1 switches — Arista 7130 (ex-Metamako, acquired 2018).** FPGA-based
Layer-1 switching; port-to-port replication at the electrical level in
**~5 ns**, Layer-2 forwarding under **~100 ns** with an optimised pipeline.

**Layer-1 switches — Cisco Nexus 3550-F/3550-H (ex-Exablaze, acquired
2019)**. Same category: port-to-port latency **under ~5 ns** for pure
Layer-1 monitoring and distribution (tap/aggregation), not general L2/L3
switching.

These are colocation-cage hardware, not cloud SKUs — they matter for the
`COLO` subgraph in `03-low-latency-market-data.md` §9's split-plane diagram,
specifically the feed-handler ingest and cross-connect layer, not for
anything running inside GCP or AWS.

Sources: [AMD Solarflare X2522 — 10/25GbE Low Latency Ethernet Adapter](https://www.xilinx.com/products/boards-and-kits/x2-series/x2522.html) ·
[Xilinx-CNS/onload — GitHub](https://github.com/Xilinx-CNS/onload) ·
[Redefining Low Latency Switching — Once Again — Arista Blog](https://blogs.arista.com/blog/redefining-low-latency-switching-once-again) ·
[Arista Acquires Metamako — Arista press release](https://www.arista.com/en/company/news/press-release/6070-pr-20180912) ·
[Nexus Ultra-Low Latency Solutions — Cisco/ESG white paper](https://www.cisco.com/c/dam/en/us/products/collateral/switches/nexus-3550-series/esg-white-paper-ultralowlatency.pdf) ·
[Cisco to acquire Exablaze for high-performance switching — TechTarget](https://searchnetworking.techtarget.com/news/252475631/Cisco-to-acquire-Exablaze-for-high-performance-switching)

---

## 25. Exchange Colocation Hubs and Cloud On-Ramps

Named as orientation anchors — long-standing, publicly documented
facilities — not as a verified, current cross-connect price/availability
list (see §21). Confirm live against the provider's facility locator before
committing a design.

| Venue | Primary colo facility | Cloud on-ramp documented there |
| --- | --- | --- |
| CME | CyrusOne, Aurora, IL | AWS Direct Connect location inside the facility (already used in `03-low-latency-market-data.md` §5 Option B) |
| NYSE | Mahwah, NJ (NYSE-owned Liquidity Center) | — |
| Nasdaq | Carteret, NJ (Equinix-owned since the 2016 Verizon acquisition) | Nasdaq, Equinix and AWS partner on cloud-enabled capital-markets infrastructure at this site |
| LSE | Slough Trading Estate, UK (Digital Realty campus) | — |

**AWS Direct Connect on-ramps, NY/NJ metro:** Equinix NY5, Secaucus (also
reachable from NY2, NY4, NY7); 165 Halsey Street, Newark; CoreSite NY1/NY2,
Manhattan.

**AWS Direct Connect on-ramps, London:** Equinix LD5, Slough (also reachable
from LD4–LD6); Telehouse West (also reachable from Telehouse Docklands).

**Google Cloud Interconnect on-ramp:** Equinix NY5, Secaucus, lists Google
Cloud Interconnect among its on-ramp services on the same campus that hosts
the Nasdaq/AWS partnership above — i.e. GCP, AWS and Nasdaq's own matching
engine are cross-connectable from the same building without a wide-area
circuit.

**Design consequence:** a private circuit into the cloud from a venue's colo
cage is frequently a cross-connect within the same building or campus to an
existing on-ramp, not a new metro fiber build — check the on-ramp roster for
the specific facility before pricing a new circuit.

Sources: [AWS Direct Connect locations](https://aws.amazon.com/directconnect/locations/) ·
[Equinix NY5](https://www.equinix.com/data-centers/americas-colocation/united-states-colocation/new-york-data-centers/ny5) ·
[NYSE Opens Mahwah Data Center — Data Center Knowledge](https://www.datacenterknowledge.com/colocation/nyse-opens-mahwah-data-center) ·
[Nasdaq breaks ground on data center expansion at Equinix facility in New Jersey — DCD](https://www.datacenterdynamics.com/en/news/nasdaq-breaks-ground-on-data-center-expansion-at-equinix-facility-in-new-jersey/) ·
[Digital Realty enhances European colocation capabilities with acquisition of data center campus in Slough — TipRanks](https://www.tipranks.com/news/press-releases/digital-realty-enhances-european-colocation-capabilities-with-acquisition-of-data-center-campus-in-slough)

---

## 26. Kernel Isolation Parameters — isolcpus / nohz_full / rcu_nocbs / Hugepages

Expands the OS-tuning bullet list in `03-low-latency-market-data.md` §4 with
the specific parameters and their interaction, since "isolate the core" is
three separate settings that must target the same CPU set to work together:

- **`isolcpus=<cpuset>`** — scheduler does not place ordinary processes on
  these cores.
- **`nohz_full=<cpuset>`** — timer tick stops firing when exactly **one**
  task is runnable on the core. Starting a second thread on that core forces
  the tick back on to multiplex — this is a common source of "tuning that
  stopped working" when a second thread lands on an isolated core.
- **`rcu_nocbs=<cpuset>`** — offloads RCU callback processing off the
  isolated cores.
- **Recent kernel convergence:** `isolcpus=nohz` was merged as equivalent to
  `nohz_full`, extended to cover the same set of kernel noise sources —
  reduces this to one parameter going forward; confirm which kernel version
  ships it before relying on the shorthand.
- **`hugepagesz=1GB hugepages=<N> default_hugepagesz=1GB`** — cuts TLB
  misses and improves initialisation time; size `<N>` against the
  application's working set.
- **Measured tradeoff, not a free lunch:** switching `CONFIG_NO_HZ_IDLE` to
  `CONFIG_NO_HZ_FULL` on a PREEMPT_RT kernel showed a consistent **~300 ns**
  average latency *increase* from context-tracking overhead in one published
  measurement. Tickless is a tail-latency and jitter tool, not an
  unconditional p50 win — measure on the target kernel and workload.
- **GCP C4 bare-metal scheduling-latency data point:** one measured study
  found standard-kernel maximum scheduling latency around **63 µs**, versus
  roughly **50 µs** on a PREEMPT_RT kernel, on the same C4 bare-metal
  hardware.

Sources: [Low Latency Tuning Guide — Erik Rigtorp](https://rigtorp.se/low-latency-guide/) ·
[sched/isolation: Make "isolcpus=nohz" equivalent to "nohz_full" — LKML](https://lkml.iu.edu/hypermail/linux/kernel/2409.2/04791.html) ·
[NO_HZ_FULL vs NO_HZ_IDLE: ~300ns cyclictest latency regression — LKML](https://lkml.iu.edu/hypermail/linux/kernel/2603.3/06802.html) ·
[CPU Isolation for HFT: The isolcpus Lie and What Actually Works](https://nikhilpadala.com/blog/cpu-optimization-linux-latency/)

---

## 27. Kubernetes and Low-Latency Workloads — GKE/EKS Mechanisms and the Anti-Pattern Boundary

Teams reach for Kubernetes by default for everything in the split-plane
architecture (`03-low-latency-market-data.md` §9). The mechanisms below make
a *bounded* low-latency pod viable; they do not make the matching-engine or
feed-handler hot path a good idea inside an orchestrated cluster.

**Kubelet-level mechanisms (GKE and EKS both — this is upstream Kubernetes,
not a GKE-only feature):**

| Setting | Effect |
| --- | --- |
| `cpuManagerPolicy: static` | Pins Guaranteed-QoS pods to exclusive whole cores instead of the shared CFS pool |
| `full-pcpus-only` / `prefer-align-cpus-by-uncorecache` options | Aligns pinned cores to physical-core and cache-topology boundaries, not hyperthread siblings |
| `topologyManagerPolicy: single-numa-node` | Refuses to schedule a pod whose CPU, memory and device (e.g. SR-IOV VF) allocations would cross a NUMA boundary |
| Reserved system CPUs (`--reserved-cpus`) | Keeps kubelet/OS daemons off the isolated core set — the Kubernetes-native equivalent of `isolcpus` (§26) |

GKE exposes these through **`NodeKubeletConfig`** on a node pool.

**Network path — the overlay tax is real and measured.** A CNI benchmark
across 500-node clusters found the wrong CNI choice can add **12 ms of p99
latency to every service call** — two to three orders of magnitude over the
network-path budget in `03-low-latency-market-data.md` §1. Ranking, cloud-
neutral: **Cilium in eBPF mode** measures within roughly **5% of bare-metal**
networking (packet processing in-kernel via eBPF, no iptables chain
traversal); **Calico in pure L3/BGP mode** (no overlay) is comparably clean;
any **VXLAN or other encapsulating overlay** (default Flannel/Weave, or
Calico/Cilium misconfigured into overlay mode) adds encapsulation overhead
on top of the CNI's own processing cost. For the genuinely hot path, **pod
`hostNetwork: true`** removes the CNI from the data path entirely — the
usual escape hatch when even the best CNI's overhead is unacceptable.

**Direct hardware access from a pod — SR-IOV + Multus + DPDK.** **Multus**
attaches a second (or third) NIC to a pod, separate from the primary
cluster-network interface, typically backed by an **SR-IOV virtual
function** so the pod gets a hardware-isolated, kernel-bypassed path — the
pattern Intel documents by name for **real-time financial systems**,
alongside live broadcast and connected-vehicle workloads. **AWS EKS supports
the Multus meta-CNI plugin.** This is the Kubernetes-native way to give one
pod the same kind of dedicated-NIC access §24's colo NICs give a bare-metal
feed handler — combine with the Topology Manager row above so the SR-IOV VF
and the pinned CPU land on the same NUMA node.

**The isolation tools cut the other way — don't add them to the hot path.**
GKE Sandbox (gVisor) intercepts syscalls in a user-space kernel for security
isolation; that interception is inherent overhead on every syscall, the
opposite of what a feed handler or matching engine wants. Reserve
sandboxed/gVisor node pools for untrusted or multi-tenant workloads, never
for the latency-critical tier.

**Where this leaves the split-plane diagram (§9):** GKE/EKS with the
mechanisms above is a defensible platform for **normalisation, fan-out,
entitlements and the API tier** — the `CLOUD` subgraph nodes that are
already one hop removed from the wire. It is not the recommended home for
the feed handler that touches the exchange multicast feed or a matching
engine with a sub-millisecond SLA — those stay on bare metal or a
purpose-built instance (§22), with Kubernetes managing everything around
them rather than that hot path itself.

Sources: [Low Latency Workloads in Kubernetes: A Practitioner's Guide — Appvia](https://www.appvia.io/blog/low-latency-kubernetes) ·
[Control Topology Management Policies on a Node — Kubernetes documentation](https://kubernetes.io/docs/tasks/administer-cluster/topology-manager/) ·
[Node Resource Managers — Kubernetes documentation](https://kubernetes.io/docs/concepts/policy/node-resource-managers/) ·
[Benchmark: Cilium 1.17 vs Calico 3.29 vs Flannel 0.25 — Kubernetes CNI Latency for 500-Node Clusters](https://dev.to/johalputt/benchmark-cilium-117-vs-calico-329-vs-flannel-025-kubernetes-cni-latency-for-500-node-clusters-4564) ·
[Advanced Networking Features in Kubernetes — Intel Network Builders](https://builders.intel.com/docs/networkbuilders/adv-network-features-in-kubernetes-app-note.pdf) ·
[miztiik/multus-on-eks — GitHub](https://github.com/miztiik/multus-on-eks) ·
[GKE Sandbox — GKE security, Google Cloud documentation](https://docs.cloud.google.com/kubernetes-engine/docs/concepts/sandbox-pods)
