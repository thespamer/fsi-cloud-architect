# Design Review Checklists

Work these end to end when reviewing an architecture. Report findings as
**Blocker / Major / Minor / Observation**, ordered by severity, each with the
concrete failure it causes and a recommendation carrying a number or a setting.

Say plainly when a design is sound. Do not manufacture findings.

**Sections:** A requirements · B connectivity · C DNS and identity · D latency and
market data · E security and compliance · F GenAI · G resilience and DR ·
H operations and cost · I enablement · J M&A integration · K documentation.
Skip F and J when they do not apply; work the rest every time.

---

## A. Requirements and Constraints

- [ ] The **business outcome** served is named — digital transformation, M&A,
      an investment programme, or GenAI enablement — and the design is traceable
      to it
- [ ] **Who operates this** is identified, and whether they can self-serve
- [ ] Latency target is stated **with its measurement point** (wire-to-wire,
      application-to-application, p50 vs p99.9)
- [ ] Throughput is stated **per direction**, at steady state and at peak, with
      the peak multiplier justified
- [ ] Availability target is stated, and the topology that earns it is drawn
- [ ] RTO and RPO are stated per component, not for "the system"
- [ ] Regulatory jurisdictions and the specific obligations are named
- [ ] Data classification is assigned to every store and flow
- [ ] Existing estate, contracts and carrier commitments are documented
- [ ] Growth assumption over the contract term is stated

**Blocker if:** the latency or availability target has no measurement definition.
Everything downstream is unverifiable.

---

## B. Connectivity and Routing

- [ ] Connectivity product chosen matches the bandwidth, lead time and resiliency
      requirement — and the choice is justified against alternatives
- [ ] **Resiliency topology matches the claimed SLA tier** (GCP 99.99% = 4
      connections, 2 metros, separate EADs; AWS 99.99% = multi-site redundant)
- [ ] No single device, facility or carrier appears in both paths
- [ ] Each circuit is sized to carry **full peak alone** when its pair fails
- [ ] Steady-state utilisation target ≤50%, with the microburst profile measured
- [ ] **MTU computed end to end**, including encapsulation, and the minimum
      identified (watch AWS transit VIF at 8500 vs private VIF at 9001, and GCP
      8896 being unavailable with encryption)
- [ ] **BFD enabled** on every hybrid and cross-cloud BGP session
- [ ] BGP authentication (MD5/TCP-AO) enabled
- [ ] Inbound prefix limits set with a warning threshold
- [ ] Advertisements summarised; no unintended default route
- [ ] Path preference explicit and documented (local pref, AS-path prepend, DX
      communities, Cloud Router priority)
- [ ] Failover has been **tested and the convergence time measured**, not assumed
- [ ] No hairpin: on-prem does not transit one cloud to reach the other without a
      stated, recorded reason
- [ ] Address plan has no overlaps; growth space reserved; transit/peering ranges
      allocated separately

**Blocker if:** the SLA is claimed but the topology does not support it, or BFD
is absent on a path carrying revenue traffic.

---

## C. DNS and Identity

- [ ] Every estate can resolve every other estate's private names
- [ ] Resolver endpoints deployed across ≥2 zones/AZs and reachable over both
      circuits
- [ ] Namespace ownership documented; no unowned split-horizon
- [ ] Resolver query volume headroom checked
- [ ] PSC / PrivateLink endpoints resolve correctly from all estates
- [ ] **No static credentials** for cross-cloud access — workload identity
      federation in both directions
- [ ] Trust policies scoped by subject, audience and condition
- [ ] Human access federated from a single IdP with group-based mapping
- [ ] Just-in-time elevation for privileged operations; no standing admin
- [ ] Break-glass accounts exist, are alerted on, and have been tested

**Blocker if:** exported service account keys or long-lived IAM access keys are
in the design.

---

## D. Latency and Market Data

- [ ] The latency budget is decomposed by layer (placement → path → instance →
      OS → application) and the dominant term identified
- [ ] Region and zone selection is justified against the data source location
- [ ] Placement strategy specified (cluster placement group / compact placement
      policy) **and the plan to verify actual placement after launch**
- [ ] Instance family choice justified with measured, not assumed, numbers;
      bare-metal considered where tail latency is the SLA
- [ ] ENA Express / SRD **not** used on a latency-critical small-message path
- [ ] Kernel version, CPU pinning, NUMA alignment, C-state and busy-poll settings
      specified for the hot path
- [ ] **Multicast handling explicitly designed** — VPCs do not forward multicast
- [ ] If TGW multicast is used: the DX/VPN/peering restriction is acknowledged,
      static vs IGMP mode chosen deliberately, Nitro requirement met for senders,
      fragmentation avoided
- [ ] If GCP is in scope: no multicast assumption anywhere (GCP has no equivalent)
- [ ] Time synchronisation meets the applicable RTS 25 tier, with **continuous
      offset monitoring and evidence retention**
- [ ] **Exchange licensing and entitlement implications** of the data's location
      and copies have been checked with the market data team
- [ ] Entitlement enforcement is an identified component with its own audit log
- [ ] Split between colo and cloud is drawn, with the boundary justified by the
      latency requirement

**Blocker if:** the design assumes multicast works in a VPC, or copies licensed
market data across a boundary without a licensing check.

---

## E. Security and Compliance

- [ ] Every obligation from §A maps to a named technical control with an owner
- [ ] Records subject to 17a-4 / 4511 are in **Compliance-mode** Object Lock or
      locked Cloud Storage retention — not Governance mode
- [ ] Retention periods derived from the regulatory clock and verified as correct
      before locking (they cannot be shortened)
- [ ] Encryption at rest with CMK/CMEK; key custody model documented; rotation
      configured
- [ ] Encryption in transit on every hop, including the private circuit, where
      policy requires it regardless of path privacy
- [ ] Data residency enforced by policy (`gcp.resourceLocations` /
      `aws:RequestedRegion`), not by convention
- [ ] **VPC Service Controls perimeter** in place on GCP for sensitive data; the
      composed AWS equivalent documented as one control
- [ ] Central, immutable log archive in a separate account/project; **GCP Data
      Access logs explicitly enabled**
- [ ] Preventive guardrails attached at OU/folder level, inherited by new
      accounts/projects
- [ ] Secrets not present in code, IaC state, images or environment variables
- [ ] Production data not present in non-production
- [ ] Segregation of duties between deploy, approve and data access
- [ ] Access recertification process defined with evidence retention

**Blocker if:** WORM retention uses Governance mode for a 17a-4 obligation, or
audit logging can be disabled by a workload identity.

---

## F. GenAI and AI/ML Workloads

Skip if there is no AI component. Otherwise this is mandatory — see
`08-genai-ml-platform.md`.

- [ ] The data boundary is defined **before** the model choice — what data the
      model may see, and whether it may leave the perimeter
- [ ] Inference path is **private** (PSC dedicated private endpoint on GCP;
      PrivateLink interface endpoint on AWS). No public endpoint in production
- [ ] **VPC Service Controls perimeter** covers the AI services in scope, and the
      known limitations are planned for: internal PyPI mirror, endpoints created
      after perimeter enrolment, agents deployed after enrolment, proxy + Cloud
      NAT if using PSC interfaces
- [ ] Serving option matches demand shape — scale-to-zero for intermittent,
      cache-aware routing for shared-prefix high-throughput, batch for offline
- [ ] **Entitlements enforced at retrieval time**, not by filtering the model's
      answer
- [ ] Indexes partitioned by data classification / licensing boundary; embeddings
      of licensed content checked against the licence
- [ ] Prompts and configurations are **versioned and immutable**; a prompt change
      is treated as a model change
- [ ] Evaluation suite gates promotion; results retained per version
- [ ] Prompt/response audit log retained under the applicable records policy, with
      the retrieval set logged, not just the answer
- [ ] Model inventory entry exists: version, owner, purpose, data, approval
- [ ] Drift, refusal-rate, latency and cost monitoring with alerting
- [ ] Third-party model provider captured in the ICT/third-party register
- [ ] EU AI Act applicability assessed — **transparency obligations are live from
      2 August 2026**; high-risk deadlines were postponed but not removed
- [ ] Unit economics defined (cost per 1,000 requests / per user / per document)

**Blocker if:** a production inference path is public, or retrieval is not
entitlement-filtered.

---

## G. Resilience, DR and Exit

- [ ] **Tier assigned from the published rubric**, with an owner who agreed it —
      not asserted by the application team
- [ ] The failure scope survived is named: **zone, region, or both** — and the
      mechanism providing it is identified. Cloud SQL HA and Multi-AZ RDS are
      *zonal* controls
- [ ] RPO is achievable with the replication chosen — zero RPO requires
      synchronous replication, and the design says which it uses
- [ ] RTO is achievable with the standby pattern chosen — near-zero RTO requires
      continuously running standby capacity
- [ ] Every single point of failure enumerated with blast radius, detection and
      recovery time
- [ ] DR strategy stated per component with tested RTO/RPO — not aspirational
- [ ] Failover tested within the required period, **measured RTO recorded**
- [ ] **Fail-back is designed**, not just failover
- [ ] Capacity in the surviving region/path verified to carry full load
- [ ] Failover does **not** depend on the control plane creating resources during
      the event — the DR path is pre-provisioned
- [ ] Dependency on shared services during a DR event analysed and each verified
      present in the DR region: **DNS, identity, secrets, container images and
      artefacts, configuration, hybrid circuits, CI/CD**
- [ ] DR region has its **own hybrid connectivity**, not a path through the failed
      region
- [ ] For regulated records: replication **preserves the retention lock**
- [ ] Restore tested, not just backup — with documented output
- [ ] Third-party register includes the cloud services supporting critical
      functions
- [ ] **Concentration risk assessed and documented**
- [ ] **Exit strategy documented and, for critical functions, exercised** — with
      the managed-service dependency inventory and migration path
- [ ] Data formats and IaC are portable enough for the stated exit timeframe
- [ ] The second cloud carries real workload, so the exit path is exercised
      continuously

**Blocker if:** a critical function has no documented exit path, in a DORA-scoped
entity.

---

## H. Operations and Cost

- [ ] Hybrid path monitored at ≤10 s resolution, with synthetic probes on every
      path including max-MTU reachability
- [ ] Application latency reported as p99/p99.9 histograms, not averages
- [ ] Clock offset monitored and retained
- [ ] Alerts route to a team that can act, with runbooks per scenario
- [ ] Change process for network changes is separate, gated and reversible
- [ ] Provider health feeds correlated into the on-call dashboard
- [ ] Cost modelled over 36 months, per option, with egress at p50 **and** p99
      volumes
- [ ] Egress asymmetry considered in placing the fan-out tier
- [ ] Tagging/labelling enforced at creation
- [ ] Commitment strategy defined for the always-on fleet
- [ ] Unit economics defined (cost per million messages, per TB retained)

**Major if:** cost is modelled only at average volume — market data cost is driven
by volatility peaks.

---

## I. Enablement and Consumability

The test most designs fail, and the one this role is judged on. See
`10-cloud-enablement.md`.

- [ ] The **business outcome** served is named — digital transformation, M&A,
      an investment programme, or GenAI enablement
- [ ] Workload teams can **self-serve** this: discoverable without asking a
      person, provisionable via IaC in under an hour, no ticket
- [ ] A **working example** exists that a team can copy and run
- [ ] Cost is **visible before committing**
- [ ] There is a **named owner to page** when it breaks
- [ ] It is **compliant by construction** — encryption, logging, tagging, network
      policy and retention come with the path, not from a later review
- [ ] The path is **opinionated**, not a wrapper with fifty options
- [ ] There is a **registered escape hatch** with a compensating control and an
      expiry date
- [ ] It is **versioned and maintained**, with a stated support model
- [ ] An **adoption metric** is defined and will be measured
- [ ] For migrations: the blocker was diagnosed before the pattern was chosen,
      and lift-and-shift is framed as a step rather than a destination

**Major if:** the design is sound but requires a ticket or the architect's
involvement to consume. It will not scale past the first team.

---

## J. M&A Cloud Integration

Skip unless this is an integration plan. See `11-ma-cloud-integration.md`.

- [ ] Integration pattern chosen deliberately — Coexist / Absorb / Re-platform /
      Rebuild — with the other three considered
- [ ] **Address overlap** assessed; the plan named; any NAT hairpin has an owner
      and an expiry date
- [ ] Guardrails apply at the destination OU/folder **before** the estate moves
- [ ] Audit logging enabled and centralised **before** any change is made
- [ ] Inherited **regulated records** identified with a date for compliant
      immutable storage
- [ ] Data and market data **licences verified as transferable** on change of
      control
- [ ] **Commitment expiry dates** known, with an owner for renegotiation
- [ ] Static credentials in the acquired estate inventoried and eliminated
- [ ] Acquired estate attached as a spoke on the existing transit, not a parallel
      transit
- [ ] DNS namespace ownership decided per namespace
- [ ] If there is a **TSA**: end date known, full service inventory built,
      replacement running in parallel before cutover
- [ ] Key-person knowledge risk identified with a retention plan
- [ ] Synergy target stated **by mechanism**, measured monthly against the deal
      model

**Blocker if:** networks are connected before guardrails and logging are in
place at the destination.

---

## K. Documentation and Decisions

- [ ] Topology diagram names every attachment, router, ASN, prefix and failure
      domain
- [ ] At least two options were considered, with the trade-off stated in the
      terms the decision turns on
- [ ] Architecture decision records exist for the irreversible choices
- [ ] Assumptions are listed and marked as verified or pending
- [ ] Open questions are listed with owners and dates
- [ ] Runbooks exist for the top failure scenarios
- [ ] Exceptions to guardrails are registered with compensating controls and
      expiry dates

**Observation if:** the design is sound but undocumented. It will be re-litigated
in six months by people who were not in the room.

---

## Review Output Template

```markdown
# Design Review: <name>
Reviewer: <name> · Date: <date> · Version reviewed: <ref>

## Verdict
<Approve | Approve with conditions | Rework required> — one paragraph of reasoning.

## Findings

### Blockers
1. **<finding>** (§<checklist ref>)
   - Failure: <what concretely breaks, when>
   - Recommendation: <change, with the number or setting>

### Major
...

### Minor
...

### Observations
...

## What the design does well
<Be specific. Reviews that only list problems get discounted.>

## Open questions for the author
1. ...
```
