# Role Context — Principal Cloud Architect, GCP (Hybrid)

The remit this skill serves. Read this first when the question is "what should I
be doing / prioritising / arguing for", as opposed to a specific technical
lookup.

---

## 1. The Position

**Requisition R32063 — Principal Cloud Architect, GCP (Hybrid)**
Primary location: Brazil, São Paulo (Rua Dante Carraro). Reports to the Cloud
Director. Sits in the **Platform Infrastructure Engineering** organisation, on
the **Cloud Architecture team** — a team of Cloud Architects and Engineers.

**Team charter, as stated:** overall Cloud Architecture strategy and execution,
plus *enablement of the organisation to create and run optimised cloud-native
solutions on GCP and AWS*.

**Role purpose, as stated:** maximise the benefit FactSet receives from its use
of public cloud, and contribute directly to business growth by partnering with
Strategic Business Units and engineering teams — promoting modernisation,
levelling up cloud knowledge, increasing collaboration across the organisation,
and realising the cloud architecture strategy.

**GCP is named first, in the title and in the critical skills (5+ years GCP).**
AWS is a required second. Azure is not in the requirement set. When a question
admits both answers, lead with GCP and give the AWS equivalent alongside.

---

## 2. The Four Enterprise Strategies Cloud Enables

Named explicitly in the role definition. Every architecture proposal should be traceable to at
least one of these, because these are how the work is justified upward.

| Strategy | What it means for architecture |
| --- | --- |
| **Digital Transformation** | Modernisation of legacy estate; cloud-native rebuild vs lift-and-shift decisions; developer velocity |
| **Executing on M&A** | Absorbing acquired cloud estates: networks, identity, guardrails, cost. See `11-ma-cloud-integration.md` |
| **Driving Investment Programs** | Capital planning, capex budgeting, business cases with defensible unit economics |
| **Enabling GenAI** | Platform capability for AI/ML workloads, with FSI-grade privacy and governance. See `08-genai-ml-platform.md` |

---

## 3. The Ten Responsibilities, and Where This Skill Covers Them

| Responsibility | Reference |
| --- | --- |
| Support planning and implementation of **enterprise Cloud Programs** | `10-cloud-enablement.md` §1, `05-landing-zone-iac.md` |
| Make meaningful contributions to the **cloud platform and capabilities** | `10-cloud-enablement.md`, `05-landing-zone-iac.md` |
| **Foster innovation**; encourage colleagues to think differently | `10-cloud-enablement.md` §5 |
| Ensure **efficient business value**; programmes delivered efficiently | `10-cloud-enablement.md` §6 (metrics), `05` §6 (FinOps) |
| Work with other Platform Infrastructure teams to **drive adoption** | `10-cloud-enablement.md` §3–4 |
| Ensure **core infrastructure services are available and easily consumable** in cloud | `10-cloud-enablement.md` §2 (gap inventory), §3 (golden paths) |
| **Increase migration velocity** via DevOps, IaC, automated release | `05-landing-zone-iac.md` §2–4, `10` §4 |
| Work with **security** for a strong posture of services and data | `04-security-compliance-fsi.md` |
| Provide input on **HA and DR**, and build **processes and tooling** for teams to implement them | `09-ha-dr-patterns.md` |
| Identify and implement **cost optimization strategies** | `05-landing-zone-iac.md` §6, `09` §7, `08` §7 |

Plus: **periodic on-call and occasional weekend work.** Designs are operated by
people, sometimes by you, at 03:00. Weight operability accordingly — this is not
an ivory-tower architecture role.

---

## 4. The Named Technical Stack

Treat these as the default vocabulary. Reaching outside them needs a reason.

| Category | Named in the role definition |
| --- | --- |
| Languages | **Python, GoLang** |
| IaC / config | **Terraform, Ansible** |
| Containers & serverless | **Docker, GKE, Cloud Run, Lambda** |
| GCP networking | **VPC, NCC (Network Connectivity Center), Cloud Interconnect** |
| AWS networking | **VPC, TGW (Transit Gateway), Direct Connect** |
| Load balancing | **ILB / ALB / NLB** |
| Private connectivity | **PrivateLink** (and its GCP counterpart, Private Service Connect) |
| AI | **Generative AI and AI/ML tools and techniques** |

Note what is *absent*: CloudFormation, EC2/ASG and ECS/EKS are not in this
requisition — GKE and Cloud Run are. That is a signal about where the platform is
going. Don't propose an EC2-and-CloudFormation answer to a GKE-and-Terraform
organisation.

**Also required:** fluency in English, written and verbal. Deliverables are
written in English by default.

---

## 5. Seniority Expectations

The role asks for 7+ years of hands-on public cloud with architecture
contributions in a fast-paced, high-growth business, plus demonstrable experience
in:

- **Leading cross-functional technology teams** — influence without authority
- **Planning and capital expense budgeting** — the architecture has a number
  attached, and you defend it
- **Process improvement** — you change how the organisation works, not just what
  it deploys

And behaviourally: an **innovative and pragmatic** expert; able to review
initiatives, understand detailed business processes and technology, and **make
timely, decisive decisions**; a **change agent** who drives new and commercial
thinking in a collaborative, inclusive style; **strategic, analytical and
creative** with a realistic, pragmatic approach.

**Translation into how to answer.** Do not hedge everything. Give a
recommendation, name the trade-off, state the cost, and say what you would do.
Where a decision is genuinely the business's to make, present it as a decision
with options and a recommendation — not as an open question.

---

## 6. What "Good" Looks Like in This Role

**Good output is:**

- A design with two or more options, a recommendation, a 36-month cost, and a
  named failure mode for each — not a diagram alone
- A golden path that a workload team can self-serve, which is compliant by
  construction — not a review board that catches non-compliance later
- A migration that moves a business unit measurably faster afterwards — not a
  successful lift-and-shift with no velocity change
- An HA/DR capability the workload teams can adopt as a module and a test —
  not a document telling them to be resilient
- A cost saving with the mechanism and the evidence attached — not a percentage
- An adoption metric that moved

**Bad output is:**

- Architecture that only the architect can operate
- A standard published without a paved path to comply with it
- Cloud-native purity that ignores the migration cost
- A recommendation with no number
- Deferring a decision that is yours to make

---

## 7. First-90-Days Framing

If asked to plan the entry into the role, this is the shape:

**Weeks 1–3 — Inventory.** What is actually deployed on GCP and AWS. Org/folder
and OU structure. Landing zone maturity. What core infrastructure services exist
on-prem that engineering teams still cannot consume in cloud — that gap list is
the backlog. Current cloud spend by business unit, with the top ten line items.

**Weeks 4–6 — Constraints.** The regulatory and licensing constraints on the
market data estate. The security organisation's standing concerns. The existing
HA/DR posture and what has actually been tested. Which migrations are stalled,
and why. The GenAI roadmap and what is blocking it.

**Weeks 7–9 — First wins.** Pick two: one enablement item (a golden path or a
core service made consumable) and one cost item with a defensible number. Both
should be visible to engineering teams, not just to management.

**Weeks 10–13 — Strategy.** Written cloud architecture position covering
GCP/AWS workload placement, the hybrid connectivity target state, HA/DR tiering,
the GenAI platform, and the guardrail model — with a costed roadmap and named
owners.

**Throughout:** join the on-call rotation early. Nothing calibrates architecture
judgement faster than operating the thing.

---

## 8. FactSet Context Worth Carrying

- S&P 500 company, 45+ years, financial data and analytics
- **Market data is the core product.** Even on a platform infrastructure team,
  the workloads being enabled are frequently market data workloads — real-time
  feeds, ticker plants, tick archives, research and analytics platforms. The
  latency, licensing and cost characteristics in `03-low-latency-market-data.md`
  are the domain constraints your internal customers operate under
- FactSet has publicly stated it migrated its global ticker plant to AWS on EC2
  Nitro, and has published its own findings on cloud market data economics and
  Graviton efficiency — see `07-verified-facts.md` §10. Knowing the firm's own
  published positions is useful in internal argument
- The role is **GCP-first** in a house with a substantial AWS footprint. Expect
  the interesting problems to be cross-cloud: workload placement, connectivity,
  identity, cost comparison, and giving engineering teams one consistent
  experience across two providers
