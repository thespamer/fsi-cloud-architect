# FSI Cloud Architect

Principal-level cloud architecture and platform enablement for financial
services, on **Google Cloud (primary) and AWS**, with on-premises and
colocation in the picture.

Built from the actual role definition: Cloud Architecture team inside Platform
Infrastructure Engineering, charter of *strategy and execution plus enablement of
the organisation to create and run optimised cloud-native solutions on GCP and
AWS*, serving four enterprise strategies — digital transformation, M&A,
investment programmes, and GenAI enablement.

---

## What's in it

| Component | Name | Purpose |
| --- | --- | --- |
| Agent | `fsi-cloud-architect` | Principal Cloud Architect persona. Designs and reviews architectures, plans cloud programmes and migrations, builds enablement artefacts, defines HA/DR tiers and tooling, architects GenAI platform capability, models cost, handles M&A integration |
| Skill | `fsi-hybrid-cloud` | The knowledge base — twelve reference files, Terraform for hybrid connectivity and a GCP platform baseline, and an operations CLI cheat-sheet |

### Skill contents

```
skills/fsi-hybrid-cloud/
├── SKILL.md                              # orientation + routing table
├── references/
│   ├── 00-role-context.md                # the remit, priorities, what "good" looks like, first 90 days
│   ├── 01-hybrid-topology.md             # transit design, routing, DNS, cross-cloud identity, load balancing (ILB/ALB/NLB)
│   ├── 02-private-connectivity.md        # Interconnect / Direct Connect / AWS Interconnect playbook + Private Service Connect / PrivateLink
│   ├── 03-low-latency-market-data.md     # latency budgets, tuning, multicast, time sync, licensing
│   ├── 04-security-compliance-fsi.md     # 17a-4, FINRA, DORA, MiFID II, SOC 2, BACEN → controls
│   ├── 05-landing-zone-iac.md            # org structure, IaC, GKE/Cloud Run standards, CI/CD, observability, FinOps
│   ├── 06-design-review-checklists.md    # eleven checklists + a review report template
│   ├── 07-verified-facts.md              # every number, with its source
│   ├── 08-genai-ml-platform.md           # Vertex AI, GKE Inference Gateway, private inference, AI governance
│   ├── 09-ha-dr-patterns.md              # tiers, patterns, dependency traps, DR tooling and testing
│   ├── 10-cloud-enablement.md            # platform as product, golden paths, adoption, migration velocity
│   └── 11-ma-cloud-integration.md        # cloud due diligence, integration, TSA exit, divestiture
└── examples/
    ├── terraform-gcp-interconnect.tf     # Dedicated + Cross-Cloud Interconnect, BFD, MTU
    ├── terraform-aws-directconnect.tf    # DX, DXGW, TGW, transit VIFs, multicast domain
    ├── terraform-gcp-platform-baseline.tf# regional private GKE + Cloud Run + CMEK + budget
    └── cli-cheatsheet.md                 # gcloud / aws / GKE / Cloud Run / Vertex / posture sweep
```

---

## How to use it

**Ask a question.** The skill triggers on cloud architecture, enablement,
networking, GKE/Cloud Run, HA/DR, GenAI platform, cost and FSI compliance topics.

**Design something.** Describe the constraints and ask for a topology or a
platform capability. You get options with a comparison table, a Mermaid diagram,
failure modes, a build path, the module interface workload teams consume, and
open questions.

**Review something.** Point it at a design document. It runs eleven checklists —
requirements, connectivity, DNS and identity, latency and market data, security
and compliance, GenAI, resilience and DR, operations and cost, enablement, M&A
integration, documentation — and returns findings graded Blocker / Major / Minor
/ Observation, each with the concrete failure and a recommendation carrying a
number.

**Invoke the agent explicitly** for larger work — a full architecture document,
an ADR set, a migration plan, a due diligence report.

---

## Design principles baked in

- **GCP first, AWS second.** When a question admits both answers, the GCP answer
  leads and the AWS equivalent comes alongside.
- **Never state a number from memory.** `references/07-verified-facts.md` holds
  every bandwidth, MTU, SLA topology, quota, latency measurement and regulatory
  date with its source. Anything not in there is flagged as needing verification.
- **Enablement outranks elegance.** Architecture nobody adopts is a rounding
  error. Prefer a golden path teams self-serve over a standard they must
  interpret.
- **Compliant by construction.** Encryption, logging, tagging, network policy and
  retention belong in the paved path, not a later review.
- **Every recommendation carries a number.** 36-month cost, RTO in minutes,
  latency in µs, adoption as a percentage.
- **SLA tiers are topologies, not purchases.** And regional products survive zone
  loss, not region loss — the design has to name the mechanism.
- **Assume no multicast.** Neither cloud's VPC forwards it.
- **Private inference by default.** Public AI endpoints are rarely acceptable in
  a financial data firm — and a perimeter that blocks the data scientists gets
  bypassed, so the package mirror ships with it.
- **Regulation constrains topology**, not just paperwork.

---

## Currency

Reference material verified **August 2026**, including AWS Interconnect
(GA April 2026), Partner Cross-Cloud Interconnect for AWS, Cloud Interconnect
400 Gbps circuits, Cloud Run GPUs, GKE Inference Gateway routing benchmarks, the
Precision Time Placement Group expansion, and the **EU AI Act Omnibus revised
deadlines** (transparency still live 2 August 2026; high-risk postponed).

Cloud specifications change. `references/07-verified-facts.md` lists what was
deliberately left out because it changes too often — pricing, per-region quotas,
facility lists, model availability, preview-vs-GA status — with instructions to
check those live.

---

## Setup

No connectors, environment variables or external services required.

## Extending it

- `references/07-verified-facts.md` — your internal circuit inventory, ASNs,
  address plan, measured latency baselines
- `references/00-role-context.md` — your own priorities as they firm up
- `references/06-design-review-checklists.md` — your review board's criteria
- `examples/` — your actual Terraform module interfaces

Keep the sourcing discipline: every number gets a citation or a "needs
verification" flag.
