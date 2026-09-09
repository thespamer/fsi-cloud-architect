# Private Connectivity Playbook

Cloud Interconnect, Cross-Cloud Interconnect, Direct Connect and AWS Interconnect
— what to choose, how to size it, and the settings that decide whether it works
at 03:00. Plus Private Service Connect and PrivateLink (§10) — a different,
narrower problem: exposing or consuming one service privately, not joining
two networks.

All figures here are sourced in `references/07-verified-facts.md`.

---

## 1. Choosing the Connectivity Product

### On-prem / colo → Google Cloud

| Option | When | Speeds | Lead time |
| --- | --- | --- | --- |
| **Dedicated Interconnect** | You can reach a Google colocation facility and need ≥10 Gbps | 10G circuits (1–8 → 10–80 Gbps); 100G circuits (1–8 → 100–800 Gbps); 400G circuits (1–8 → 400–3200 Gbps) | Weeks — cross-connect ordering |
| **Partner Interconnect** | You cannot reach a Google facility, or need sub-10 Gbps granularity | Partner-defined, sub-10 Gbps upward | Days |
| **HA VPN** | Backup path, low volume, or bridging while circuits are built | IPsec over internet or over Interconnect | Minutes |

### On-prem / colo → AWS

| Option | When | Speeds | Lead time |
| --- | --- | --- | --- |
| **Direct Connect – Dedicated** | You need a full port and maximum control, or MACsec | 1, 10, 100, 400 Gbps | Weeks |
| **Direct Connect – Hosted** | Partner-provisioned logical connection, faster to obtain | 50 Mbps – 25 Gbps | Days |
| **AWS Interconnect – Last Mile** | You want AWS to handle the whole path including the carrier | 1 – 100 Gbps, adjustable in console | Managed; partner-dependent |
| **Site-to-Site VPN** | Backup, low volume, or bridge | Per-tunnel limits apply | Minutes |

**AWS Interconnect – Last Mile** (GA April 2026) is materially different from
ordering DX yourself: it automatically provisions **four redundant connections
across two physical locations**, configures BGP, and turns on **MACsec and jumbo
frames by default**. Launch partner Lumen; AT&T and Megaport in progress. When
the team is small or time-to-deliver dominates, this is usually the better buy
than hand-assembling a maximum-resiliency DX deployment.

### Google Cloud ↔ AWS

| Option | Characteristics |
| --- | --- |
| **Cross-Cloud Interconnect (Google-side)** | Google provisions the circuit to AWS. 10 / 100 / 400 Gbps for AWS. Jumbo MTU configurable. Same SLA tiers as Cloud Interconnect |
| **Partner Cross-Cloud Interconnect for AWS** | No physical provisioning. Minutes rather than 1–4 weeks. Granular 1–100 Gbps. Built-in resiliency, no manual redundancy design. GA as of Next '26 |
| **AWS Interconnect – Multicloud (AWS-side)** | Managed L3 private connection, traffic stays on provider backbones, **MACsec on by default**, redundant facilities built in. Google Cloud supported now; Azure and OCI later in 2026. Attaches to a Direct Connect Gateway |
| **Carrier NaaS (Megaport, Equinix Fabric, PacketFabric)** | Provider-neutral, one contract for many clouds, useful when you already have a colo footprint. You own the resiliency design |
| **IPsec over internet** | Control plane, low volume, or emergency only. Not for market data volumes |

**Decision rule.** If either provider's managed multicloud product covers the
metro pair and the bandwidth, use it — the resiliency and encryption defaults are
better than most hand-built designs, and the provisioning time is a fraction.
Choose carrier NaaS when you need one fabric across more than two clouds plus
colo, or when commercial terms with the carrier are already favourable.

---

## 2. Resiliency Tiers — Build the Topology, Then Claim the SLA

### Google Cloud Interconnect

| Target | Required topology |
| --- | --- |
| **99.99%** | At least **4 connections**: 2 in one metro and 2 in another metro; within each metro the two must be in **different edge availability domains (EADs)** |
| **99.9%** | At least **2 connections** in the same metro, in **different EADs** |

Cross-Cloud Interconnect follows the same tiers: 99.99% needs two connection
pairs across different metros, each pair using separate EADs; 99.9% needs a
primary and redundant connection in different EADs within one metro.

### AWS Direct Connect

| Model | Topology | SLA |
| --- | --- | --- |
| **Maximum Resiliency** (multi-site redundant) | Separate connections on separate devices, across multiple locations, redundant hardware per site | **99.99%** |
| **High Resiliency** (multi-site non-redundant) | One connection at each of two locations | **99.9%** |
| **Single-site redundant** | Two connections on different devices at one location | Not recommended for production |
| **Single connection** | One connection | **92.5%** |

AWS states plainly that for production workloads it does not recommend anything
other than multi-site redundant or multi-site non-redundant.

**Service credit tiers** (Direct Connect): Multi-Site Redundant — 10% credit
below 99.99%, 25% below 99.0%, 100% below 95.0%. Multi-Site Non-Redundant —
10% below 99.9%, 25% below 99.0%, 100% below 95.0%. Single Connection — 10%
below 92.5%, 25% below 90.0%.

**Interpretation for FSI.** Credits are irrelevant next to the cost of an outage
on a market data path. Treat the SLA as a statement of the topology the provider
believes is necessary, not as financial protection. Build the 99.99% topology for
anything client-facing or revenue-bearing.

---

## 3. Capacity Sizing

Do this arithmetic explicitly; it is the most commonly skipped step.

1. **Baseline.** Measure or estimate steady-state throughput per direction, in
   Mbps, at p50 and p99.
2. **Peak multiplier.** Market data peaks are not gentle. Use the observed ratio
   of open/close/volatility-event bursts to steady state — 5–20× is common for
   equities feeds. Size to p99.9 of the burst, not the mean.
3. **Survivor sizing.** With N circuits active/active, each surviving circuit must
   carry the full peak when one fails. Two circuits ⇒ each sized for 100% of peak,
   not 50%.
4. **Headroom.** Target ≤50% utilisation per circuit at steady state. Above 70%
   sustained, TCP behaviour degrades and microbursts start dropping.
5. **Growth.** Add the annual growth rate over the contract term. Re-ordering a
   port takes weeks.
6. **Compare against egress.** For each candidate size, compute
   `metered egress cost` vs `port cost + committed transfer`. The crossover is
   often lower than teams expect.

**Microbursts.** Interface counters averaged over 5 minutes hide bursts that fill
a 10 Gbps link for 200 ms. If the workload is market data, measure at
sub-second granularity or accept that you will discover the ceiling during a
volatility event.

---

## 4. MTU: Get This Right Once

| Path | Supported MTU |
| --- | --- |
| **GCP VLAN attachment** | 1440, 1460, 1500 or **8896** bytes. 8896 is restricted to unencrypted IPv4/IPv6 |
| **AWS private VIF** | 1500 or **9001** |
| **AWS transit VIF** | 1500 or **8500** — note this is lower than private VIF |
| **Mixed routes** (multiple VIFs / VPN with different MTU) | **1500 wins** |

Rules:

- The end-to-end MTU is the **minimum along the path**, including the on-prem
  side, any GRE/IPsec overhead, and the cross-cloud segment. Compute it, do not
  assume it.
- A GCP↔AWS path through GCP at 8896 and AWS transit VIF at 8500 is an **8500**
  path at best. Encapsulation shrinks it further.
- Changing MTU on a Direct Connect connection causes **up to 30 seconds of
  disruption** across all VIFs on that connection. Schedule it.
- Transit Gateway **does not fragment**; fragmented packets are dropped. Jumbo
  misconfiguration on a TGW path is silent packet loss, not a slow path.
- Enable **PMTUD** and verify ICMP is not being filtered by on-prem firewalls,
  or MTU black holes will present as "some large responses hang".

---

## 5. Encryption on the Wire

| Layer | GCP | AWS |
| --- | --- | --- |
| **L2 (MACsec)** | Supported on Dedicated Interconnect | Supported on **10, 100 and 400 Gbps** connections at select locations. On by default on AWS Interconnect (both variants) |
| **L3 (IPsec)** | HA VPN, including **HA VPN over Cloud Interconnect** | Site-to-Site VPN, including VPN over Direct Connect |
| **Application** | mTLS between services | mTLS between services |

Guidance for FSI:

- **MACsec is the low-overhead option** and should be the default where the
  location supports it. It does not reduce MTU the way IPsec does.
- **IPsec over Interconnect/DX** is the answer when a policy mandates encryption
  and MACsec is unavailable at the facility — accept the MTU and throughput cost.
- **Do not treat "private circuit" as equivalent to "encrypted".** Many FSI
  control frameworks require encryption in transit regardless of path privacy.
  Confirm which the firm's policy demands before designing around it.
- Jumbo frames (8896 on GCP) are **not available with encryption** on the GCP
  attachment. Choose one.

---

## 6. BGP Configuration Standards

Apply to every hybrid and cross-cloud session.

| Setting | Standard | Why |
| --- | --- | --- |
| **BFD** | Enabled on every session that supports it | Default BGP hold time means ~90 s blackhole; BFD detects far faster |
| **MD5 / TCP-AO** | Enabled on all sessions | Prevents session hijack and is a common audit expectation |
| **Prefix limits** | Set inbound maximum-prefix with a warning threshold | A leaked full table takes down the session, not the router |
| **Advertisement scope** | Summarised, explicitly listed, no `default` unless intended | Both clouds cap learned prefixes per session |
| **Graceful restart** | Enabled where supported | Avoids traffic loss on control-plane restarts |
| **Path preference** | Explicit — local preference outbound, AS-path prepend or DX communities inbound | Failover must be deterministic and documented |
| **Logging** | BGP state changes to SIEM | Session flaps are the earliest signal of circuit degradation |

### BFD — the exact parameters, and the trap

**Google Cloud Router**

| Parameter | Range | Default |
| --- | --- | --- |
| Minimum transmit interval | 1000–30,000 **ms** | 1000 ms |
| Minimum receive interval | 1000–30,000 **ms** | 1000 ms |
| Multiplier | 5–16 packets | 5 |
| Session initialization mode | Active / Passive / **Disabled** | **Disabled** |

**The trap:** the default is *Disabled*, so BFD is off unless you set it. And BFD
on Cloud Router is supported **only on Dedicated and Partner Interconnect VLAN
attachments running Dataplane version 2** — it is **not** supported on HA VPN
tunnels or on router appliance (NCC) spokes. Check the attachment first:

```bash
gcloud compute interconnects attachments describe VA --region=R \
  --format="value(dataplaneVersion)"
```

If a design leans on BFD for fast failover over HA VPN, it does not have it.
Plan around shorter BGP timers instead, and say so explicitly.

**AWS Direct Connect**

Asynchronous BFD is **automatically enabled on the AWS side of every virtual
interface**, but **does not take effect until you configure it on your router**.
AWS-side values: liveness detection minimum interval **300**, multiplier **3**.
There is no Terraform argument — this is a router-side change. A team that
assumes "AWS enables it" and never touches the router has no BFD.

**AWS Direct Connect local preference communities:** `7224:7100` (low),
`7224:7200` (medium), `7224:7300` (high) tag your advertisements to control which
DX path AWS prefers when returning traffic.

**GCP Cloud Router route priority:** lower value is preferred. Use it to make one
metro primary and the other standby, or leave equal for ECMP.

**On-prem router prerequisites for GCP Dedicated Interconnect:** LACP,
EBGP-4 multi-hop, 802.1Q VLANs, single-mode fibre within 10 km of the Google
peering edge.

---

## 7. Operating the Circuits

**Monitoring that matters**

- BGP session state and route counts, per session, alerting on flap rate
- Interface utilisation at ≤10 s resolution (5-minute averages hide microbursts)
- Interface errors, CRCs, discards — these precede failures
- Per-attachment latency and packet loss, measured continuously with synthetic
  probes, not only when someone complains
- Both clouds' service health feeds, correlated with your own telemetry

**Change discipline**

- Never change both metros in the same window
- Validate the surviving path carries full peak load before touching the other
- Keep a tested rollback for every BGP policy change; policy changes propagate
  faster than you can revert manually
- Record maintenance windows from the carrier and both cloud providers in one
  calendar

**Scheduled failover testing.** Quarterly at minimum. Shut one session, measure
convergence, confirm application-level impact, restore. Document the measured
convergence time — it is the number the business actually needs, not the SLA.

---

## 8. Cost Model

| Cost element | GCP | AWS |
| --- | --- | --- |
| Port / circuit | Per-hour per Interconnect connection | Per-hour per DX port |
| VLAN attachment | Per-attachment charge, capacity-based | VIFs included |
| Egress over the circuit | Reduced rate vs internet egress; local vs remote metro pricing on Cross-Cloud Interconnect | DX data transfer out rate, lower than internet |
| Cross-cloud | Fixed port pricing available on Cross-Cloud Interconnect | Interconnect – Multicloud pricing |
| Carrier / colo | Cross-connect, cage, power, carrier circuit | Same |

**Build the model as a spreadsheet with these rows**, one column per option:
port cost, attachment cost, egress at p50 volume, egress at p99 volume, carrier,
colo, one-off install, and a 36-month total. The answer is frequently not the
cheapest monthly line — it is the option whose cost does not scale with a
volatility event.

**Egress asymmetry.** Ingress to both clouds is generally free; egress is not.
Architectures that pull data into a cloud are cheap; architectures that fan data
out of one are expensive. For market data distribution, that asymmetry should
drive where the fan-out tier lives.

---

## 9. Common Failure Scenarios and Their Design Answers

| Scenario | Design answer |
| --- | --- |
| Single fibre cut in one metro | Second metro carries full peak; BFD detects in <1 s; verified by quarterly test |
| Provider edge device maintenance | Separate EADs (GCP) / separate devices (AWS) so one device is never both paths |
| BGP misadvertisement from on-prem | Inbound prefix limits and explicit filters on the cloud side |
| Circuit saturation during a volatility event | Headroom target ≤50%, QoS/marking for control traffic, and a documented shed order for non-critical flows |
| Cross-cloud path down | Fall back to routing via on-prem if the address plan and capacity permit — design and test this, do not assume it |
| MTU mismatch after a change | Standing synthetic test that sends max-MTU DF packets end to end on every path |
| Complete cloud region loss | Second region attached over its own circuits, with the data replication path sized and tested |

---

## 10. Private Service Connect and PrivateLink — a Different Problem Than §1–9

Everything above this section is about **joining networks** — two sites that
need a routable path between their whole address spaces. Private Service
Connect (GCP) and PrivateLink (AWS) solve a narrower, more common problem:
**let one specific service be consumed privately, without joining the
networks it lives in.** Confusing the two leads to over-building — running a
full Interconnect or a peering mesh to reach a single API that a PSC endpoint
or an interface endpoint would have solved in an afternoon.

**Mechanics, briefly** (full detail and sources in `07-verified-facts.md` §14):

- **PSC (Google Cloud):** consumer creates a PSC endpoint — a forwarding rule
  with an internal IP in their own VPC — that attaches to a service
  attachment the producer publishes, fronted by an internal passthrough
  Network Load Balancer. No peering, no transitive-routing problem, no CIDR
  overlap to negotiate. Same mechanism also fronts Google APIs (PSC for
  Google APIs) and, in the reverse direction, lets a producer reach into a
  consumer's VPC (PSC interfaces).
- **PrivateLink (AWS):** provider publishes a VPC endpoint service backed by
  an NLB (or a Gateway Load Balancer, for inline appliance insertion).
  Consumer creates an interface endpoint (an ENI with a private IP) in their
  own subnet, or — for S3/DynamoDB only — a routed gateway endpoint. Since
  November 2024, interface endpoints can reach a VPC endpoint service in a
  **different AWS Region** without cross-region peering.

**When this is the right tool, in FSI terms:**

- Publishing a market-data or reference-data API to a subsidiary, an acquired
  entity mid-integration (see `11-ma-cloud-integration.md`), or an external
  partner — without handing them a route into the wider VPC or estate
- Consuming a SaaS vendor's endpoint privately — most vendors serving
  regulated customers now publish a PrivateLink/PSC front door precisely so
  the traffic never touches the public internet
- One platform team publishing a shared internal service (secrets, a feature
  store, a model endpoint — see `08-genai-ml-platform.md` §2) to every
  consuming team, without a peering mesh that grows as O(n²)
- Any cross-account/cross-project service consumption where the consumer
  should get access to *the service*, not visibility into the producer's
  network

**When it is the wrong tool:** the consumer needs to reach many services, or
services that don't exist yet, in the producer's network — that is a
peering, NCC/TGW, or Interconnect/Direct Connect problem (§1–9), not a
one-endpoint-at-a-time problem. Standing up a PSC endpoint per service does
not scale past a few dozen before the operational overhead argues for a hub
model instead.

**Design review points:**

- Does the DNS name resolve to the private endpoint from every estate that
  needs it, not just the one it was built for? (See `01-hybrid-topology.md`
  §5.)
- For a published service: is the producer-side load balancer's health check
  and failover independent of any one zone?
- For AWS cross-region PrivateLink: is the consumer region on the current
  supported list? (Confirm — `07-verified-facts.md` §14 records the launch
  list, which will have grown.)
- Is there a plan for what happens when a consumer needs *more than one*
  service from the same producer — one endpoint per service, or time to
  reconsider a hub topology?
- If the answer to the point above is "reconsider a hub topology": is the
  third party being attached as a full spoke on the *existing* transit hub —
  which gives it a path to every other spoke already there, not just to
  you? A dedicated edge VPC/project as the spoke, with custom route export
  filtering and hierarchical firewall policy scoping what it can reach, keeps
  the blast radius to the relationship rather than the whole estate. The
  general principle ("two estates fully routed to each other doubles the
  blast radius") is written for M&A integration in
  `11-ma-cloud-integration.md` §4, but it applies to any third party, not
  only an acquired entity — see the anti-pattern entry in
  `01-hybrid-topology.md` §9.
