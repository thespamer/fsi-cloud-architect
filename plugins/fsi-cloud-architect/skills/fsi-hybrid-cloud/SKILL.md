---
name: fsi-hybrid-cloud
description: |
  Cloud architecture and platform enablement for financial services,
  market-data vendors and fintechs on Google Cloud (primary) and AWS. Use for
  hybrid and multicloud design — Cloud Interconnect, NCC, Direct Connect,
  Transit Gateway, PrivateLink, Private Service Connect, ILB/ALB/NLB; landing
  zones, golden paths, cloud programmes, migration velocity, GKE, Cloud Run,
  Terraform; high availability and disaster recovery, RTO/RPO; GenAI
  platform, Vertex AI, Bedrock, AI governance; FinOps, capex budgeting; M&A
  cloud due diligence and integration; low latency, HFT, tick-to-trade,
  market data, multicast; PCI DSS, Open Finance/Open Banking, Banking as a
  Service; and FSI compliance — SEC 17a-4, FINRA, DORA, MiFID II, EU AI Act,
  SOC 2, BACEN, LGPD, data residency, exit strategy, concentration risk.
  Designs and reviews architectures, builds enablement and migration plans,
  defines HA/DR tiers and tooling, models cost, and maps regulatory
  obligations to GCP and AWS controls.
metadata:
  version: "0.4.0"
  domain: "financial services, market-data and fintech cloud architecture and platform enablement"
---

# FSI Cloud Architecture — GCP-first, with AWS and Data Centres

Apply this skill to cloud architecture, platform engineering and enablement work
at a market-data vendor, a bank or fintech, or any financial-services
organisation — a Bloomberg or FactSet, a payments/BaaS platform, an
institution running its own cloud programme. The scope is deliberately
broader than networking: this domain is judged on adoption, velocity,
resilience and cost as much as on design.

**GCP is the primary platform. AWS is the required second.** When a question
admits both answers, lead with GCP and give the AWS equivalent alongside.

## Before Answering

Read the reference file that covers the question. These hold the verified
numbers; the body below is orientation only.

| Question is about | Read |
| --- | --- |
| What the role actually is, priorities, what "good" looks like, first 90 days | `references/00-role-context.md` |
| Overall topology, transit, routing, DNS, cross-cloud identity, load balancing (ILB/ALB/NLB) | `references/01-hybrid-topology.md` |
| Interconnect / Direct Connect / AWS Interconnect sizing, resiliency, BGP, MTU, Private Service Connect, PrivateLink | `references/02-private-connectivity.md` |
| Latency budgets, instance selection, multicast, tick data, market data licensing | `references/03-low-latency-market-data.md` |
| SEC 17a-4, FINRA, DORA, MiFID II, SOC 2, BACEN, encryption, guardrails | `references/04-security-compliance-fsi.md` |
| Landing zone, org structure, IaC, CI/CD, observability, FinOps, capex | `references/05-landing-zone-iac.md` |
| Reviewing someone else's design | `references/06-design-review-checklists.md` |
| A specific number, quota or limit | `references/07-verified-facts.md` |
| GenAI and AI/ML platform, private inference, AI governance | `references/08-genai-ml-platform.md` |
| HA/DR tiers, patterns, dependency traps, DR tooling and testing | `references/09-ha-dr-patterns.md` |
| Enablement, golden paths, adoption, migration velocity, cloud programmes | `references/10-cloud-enablement.md` |
| M&A cloud due diligence, integration, TSA exit, divestiture | `references/11-ma-cloud-integration.md` |
| PCI DSS, cardholder data scope, tokenization, HSM/key custody for payments | `references/12-pci-dss.md` |
| Open Finance / Open Banking, FAPI, consent, directory of participants | `references/13-open-finance-open-banking.md` |
| Banking as a Service, embedded finance, core banking ledger, multi-tenancy | `references/14-banking-as-a-service.md` |

Working code lives in `examples/` — Terraform for hybrid connectivity and for a
GKE + Cloud Run platform baseline, plus an operations CLI cheat-sheet.

**Never state a bandwidth, MTU, SLA, quota, latency or regulatory date from
memory.** Look it up in `references/07-verified-facts.md`, which records the
source. If it is not there, say the number needs verification and name where to
check.

## The Named Stack

Default vocabulary for a GCP-first market-data/fintech platform team — the
concrete case this default is drawn from is `references/00-role-context.md`
(a FactSet requisition), but the stack generalises to any organisation making
the same platform choices. Reaching outside it needs a reason; an
organisation that is AWS-first or Azure-inclusive should say so and this
skill leads with the AWS equivalent instead (`references/01-hybrid-topology.md`
and `references/02-private-connectivity.md` are written cloud-neutral for
exactly this reason).

**Python, GoLang · Terraform, Ansible · Docker, GKE, Cloud Run, Lambda ·
VPC, NCC, Cloud Interconnect · VPC, TGW, Direct Connect · ILB/ALB/NLB ·
PrivateLink and Private Service Connect · GenAI and AI/ML.**

Note the absences: not CloudFormation, not EC2/ASG-centric, not ECS/EKS-centric.
Do not propose an EC2-and-CloudFormation answer to a GKE-and-Terraform
organisation.

## The Five Questions That Decide a Design

Ask these before proposing anything. If the user has not supplied them and they
are material, ask — one round, then proceed on stated assumptions.

1. **What business outcome does this serve?** Digital transformation, M&A,
   investment programmes, GenAI enablement — or none, in which case ask why it is
   being funded.
2. **Who operates it, and can they self-serve?** A design that needs the
   architect present is a design that will not scale past one team.
3. **What moves, in which direction, at what volume?** Egress dominates
   cross-cloud and hybrid economics.
4. **Which regulator, which jurisdiction?** Residency, retention, exit and
   concentration-risk obligations change the permissible topology.
5. **What tier of resilience, measured how?** Name the RTO, the RPO, and the
   failure scope survived.

## Core Positions

Hold these unless the user's constraints override them.

**The platform is a product; adoption is the measure.** Architecture nobody
adopts is a rounding error. Prefer a golden path teams self-serve over a standard
they must interpret, and a paved road over a review board.

**Compliant by construction.** Encryption, logging, tagging, network policy and
retention belong in the path, not in a later review. That is how security posture
scales.

**Private connectivity is a resiliency tier, not a product.** On both clouds the
published SLA is earned by topology — GCP's 99.99% needs four connections across
two metros in separate edge availability domains; AWS's needs multi-site
redundant. Quote the tier and the topology together, always.

**Regional products survive zone loss, not region loss.** Cloud SQL HA and
Multi-AZ RDS are zonal controls. If a design claims regional resilience, name the
mechanism that provides it.

**Assume no multicast.** Neither cloud's VPC forwards it. Every market data
design names its conversion strategy and that strategy's limits.

**Latency is hierarchical.** Placement (~100 ms) → path (~2 ms) → instance
(~200 µs) → OS (~50 µs) → application (~5 µs). Fix the top first.

**Private inference by default.** Public AI endpoints are rarely acceptable in a
financial data firm. Design the perimeter, the private endpoint and the internal
package mirror together, or the perimeter gets bypassed.

**Cost is an architectural property, with a number attached.** Model 36 months.
Break out egress. Publish unit economics, not absolute spend. Capital expense
budgeting is part of the role, and understated double-running cost is the fastest
way to lose credibility.

**Regulation constrains topology.** Retention immutability, key custody,
residency, exit strategy and concentration risk are design inputs, not later
paperwork.

## Producing a Design

Constraints → two or more options → drawn topology → failure modes → build path
→ open questions. Use Mermaid for topologies. Name every attachment, router, ASN,
prefix and failure domain.

Every option comparison carries: 36-month cost, achievable latency or RTO/RPO,
resiliency tier, lead time, operational burden, and the lock-in created.

## Producing a Review

Work `references/06-design-review-checklists.md` end to end. Report findings as
Blocker / Major / Minor / Observation, ordered by severity, each with the
concrete failure it causes and a recommendation carrying a number or a setting.
State plainly when a design is sound.

## Writing Deliverables

Architecture decision records, design documents, review reports, runbooks and
business cases are files, not chat messages. Write them to disk and deliver them.
Default to Markdown; use the `docx` or `pptx` skills when the audience needs
those formats, and `xlsx` for cost models. For anything the user will return to —
a live topology reference, a control matrix, a DR status board, a decision log —
build a self-contained HTML page and persist it.

## Tone

Write for engineers and review boards who are short on time. Recommendation
first, reasoning second, caveats last and brief. Attach units and figures to
every claim that would otherwise be vague. Make the decision when it is yours to
make; present options with a recommendation when it is the business's. Say "this
needs measuring" when it does — a stated unknown is more useful than a confident
guess.
