# M&A Cloud Integration

"Executing on M&A" is one of the four enterprise strategies cloud enables. For a
cloud architect that means two distinct jobs: **technical due diligence before
the deal**, and **integration after it**. They need different skills and are
usually done by the same person.

---

## 1. Pre-Deal: Cloud Technical Due Diligence

Time is short and access is limited. Prioritise the findings that change the
price or the integration plan.

### The ten questions that matter

1. **What is the actual monthly cloud run rate**, by provider, by environment,
   for the last 12 months? Trend, not a point. Ask for the billing export, not a
   summary slide.
2. **How much of that is committed** — reserved instances, savings plans,
   committed use discounts, enterprise agreements — and **when does it expire**?
   Commitments transfer awkwardly and expiry can produce a step change in cost.
3. **What is in the enterprise agreement**, and is there a minimum spend
   commitment the acquirer inherits?
4. **Is there a single organisation/tenancy**, or a sprawl of individually-owned
   accounts and projects? Sprawl is the single biggest integration cost driver.
5. **What is the IP address plan**, and does it overlap with ours? This is the
   most common technical blocker and it is expensive to fix late.
6. **What regulated data exists, where, and under which retention obligations?**
   Inherited retention obligations are inherited liability.
7. **What is the identity model** — own IdP, federated, or local accounts with
   static keys? Local static keys are a security finding and a migration task.
8. **What third-party and open-source dependencies** carry licence obligations
   that change on a change of control?
9. **What is genuinely single-sourced** — a person, a vendor, an undocumented
   system? Key-person risk in infrastructure is normal in smaller targets.
10. **What is the security posture** — public buckets, unencrypted stores, absent
    logging, unpatched estate? Assume the worst until evidenced, and price
    remediation.

### Findings that change the number

- Unmodelled egress or licensing costs that appear post-close
- Retention obligations requiring immutable storage not currently in place
- A rebuild disguised as a migration — an architecture that cannot be absorbed
- Commitment cliffs within 12 months of close
- Overlapping address space across a large estate (renumbering is quarters, not
  weeks)
- Compliance gaps that must be closed before the acquirer's own certifications
  can cover the entity

### Deliverable

A one-page finding summary with: run rate, integration cost estimate with a
range, integration timeline, the top five risks with mitigations, and a
recommended integration pattern (§3). Then the detail behind it. Deal teams read
the page.

---

## 2. Day One: Stabilise, Do Not Integrate

The most common M&A integration error is starting integration on day one.

**Day-one priorities, in order:**

1. **Visibility.** Read-only access to their cloud billing, org structure and
   security findings. You cannot manage what you cannot see.
2. **Contain the risk.** Public exposure, absent MFA, static keys, missing
   logging. These are hours-to-days fixes with high value.
3. **Preserve evidence.** Enable and centralise audit logging before anything
   changes. If something is wrong, you want the record from before your changes.
4. **Stop the bleeding on cost.** Idle resources, orphaned volumes, oversized
   non-production. Usually 10–20% with no architectural change.
5. **Freeze non-essential change** in the target estate briefly while you map it.
6. **Talk to their engineers.** They know where the bodies are, and their
   retention is a real risk. An acquirer that arrives with a plan and no
   questions loses them.

Integration planning starts in week two, from evidence rather than assumption.

---

## 3. Integration Patterns — Choose Deliberately

| Pattern | What it means | Right when | Cost / time |
| --- | --- | --- | --- |
| **Coexist** | Leave the estate where it is; connect networks and identity only | Divestiture likely; regulatory separation required; short-term hold | Low / weeks |
| **Absorb** | Move accounts/projects into our organisation; apply our guardrails; leave the workloads as they are | Most common and usually correct | Medium / months |
| **Re-platform** | Absorb, then move workloads onto our golden paths | The estate is small, or the workloads are strategic | High / quarters |
| **Rebuild** | Rewrite on our platform | The acquired technology is the asset and the implementation is not | Highest / quarters–years |

**Default to Absorb.** It gets governance, security and cost under control
quickly without betting the integration on a simultaneous re-architecture.
Re-platform selectively afterwards, workload by workload, with a business case
each time.

**The discipline that makes Absorb work:** the acquired estate joins the
organisation and the guardrails *before* anyone tries to improve it. Guardrails
first, optimisation second.

---

## 4. The Technical Workstreams

### Organisation and accounts

- **AWS**: accounts can be invited into the acquirer's Organization. Sequence
  matters — check billing, existing SCPs, and any Control Tower enrolment.
  Removing an account from its old org and inviting it into the new one has
  prerequisites; do a readiness assessment before the window.
- **GCP**: projects can be migrated between organisations. Requires the right
  roles at both ends and careful handling of billing accounts, org policies and
  Shared VPC attachments.
- **In both cases**: apply guardrails at the destination OU/folder *before*
  moving, so the estate lands inside the controls rather than being retrofitted.

### Networking — the hard one

**Overlapping RFC1918 is the default state, not the exception.** Plan for it.

| Situation | Approach |
| --- | --- |
| No overlap | Connect directly. Rare and lucky |
| Small overlap, small estate | Renumber the overlapping segments before connecting |
| Large overlap, large estate | Isolate behind NAT or PUPI, connect only what must connect, and schedule renumbering as a funded programme |
| Overlap in a system being retired anyway | Do not renumber. Connect a proxy or a data path only, and let it die |

**Rules:**

- **NAT is a bridge, not a destination.** Permanent NAT destroys source-IP
  attribution, which breaks incident forensics and some compliance controls.
  Every NAT hairpin gets an expiry date and an owner.
- **Connect the minimum.** Two estates fully routed to each other doubles the
  blast radius on day one. Start with the specific flows the business needs.
- **DNS is the second problem.** Namespace collisions, split-horizon, and two
  authoritative sources. Decide ownership per namespace and write it down — see
  `01-hybrid-topology.md` §5.
- **Transit**: attach the acquired estate as a spoke on the existing NCC hub or
  Transit Gateway rather than building a parallel transit. One transit design per
  organisation.

### Identity

- Federate the acquired estate to the acquirer's IdP early — it is a
  high-value, contained change.
- Inventory and eliminate static credentials. This is usually a large number.
- Map their role model to yours before migrating users, not during.
- Preserve their audit trail; do not lose the pre-integration record.

### Security and compliance

- Apply preventive guardrails at the destination before the move.
- Run the acquirer's detective controls (Security Command Center, Security Hub,
  Config) against the estate immediately and triage.
- **Inherited retention obligations**: identify regulated records and get them
  under compliant immutable storage. This is often the largest single
  remediation.
- Bring the entity into the acquirer's third-party register and DORA scope, if
  applicable.

### Data

- Data residency of the acquired data may differ from yours; verify before moving
  anything.
- Licensing — especially market data licensing — does not automatically transfer
  on a change of control. Check every feed and every redistribution right before
  assuming the data can be used in the combined entity.
- Retention obligations follow the record, not the entity.

### Cost

- Consolidate billing early; the acquirer's committed-use pricing and volume
  tiers usually improve the acquired estate's unit costs immediately. This is
  frequently the fastest, largest, lowest-risk synergy available.
- Reconcile commitments — do not let inherited commitments expire unnoticed, and
  do not double-commit.
- Tag/label the acquired estate to the acquirer's schema so it appears in
  showback from month one.
- Track synergy against the deal model, monthly, with the mechanism named. "We
  saved 18%" is not evidence; "we consolidated to the enterprise agreement and
  the committed-use discount, here is the before and after" is.

---

## 5. TSA Exit

If the target is carved out of a larger company, there will be a Transition
Services Agreement — the seller provides IT services for a period, expensively,
and it ends on a fixed date.

- **The TSA end date is a hard deadline.** Work backwards from it and add
  contingency; TSA extensions are punitively priced and sometimes refused.
- **Inventory every service covered by the TSA** and assign an owner and a target
  state to each. The forgotten ones — DNS, certificates, a monitoring system, an
  internal CA — are what cause the crisis in the final month.
- **Stand up the replacement and run in parallel** before cutting over. A
  big-bang TSA exit on the deadline is how outages happen.
- **Data extraction is usually underestimated.** Formats, volumes, egress cost
  and the seller's cooperation are all variables. Start early and test a full
  extraction, not a sample.

---

## 6. Divestiture — The Mirror Image

Worth having a position on, because acquisitive firms also divest.

- **Separability is an architecture property.** An estate with clean account and
  project boundaries per business unit divests cheaply; a shared-everything
  estate divests painfully. Argue for the boundary at design time on these
  grounds, not only on blast-radius grounds.
- **Shared services are the problem** — identity, DNS, monitoring, CI/CD,
  networking. Know which ones a business unit depends on before it is for sale.
- **Data separation** is usually harder than compute separation.
- The **exit-strategy work DORA already requires** (see
  `04-security-compliance-fsi.md` §8) overlaps substantially with divestiture
  readiness. Do it once, use it twice — and make that argument when asking for
  the budget.

---

## 7. Review Questions

For an M&A cloud integration plan:

1. Which integration pattern, and why not the other three?
2. Is there address overlap? What is the plan, and does any NAT have an expiry
   date and an owner?
3. Do guardrails apply at the destination *before* the estate moves?
4. What regulated records are inherited, and when do they reach compliant
   immutable storage?
5. Have data and market data licences been verified as transferable?
6. What are the commitment expiry dates, and who owns the renegotiation?
7. Is there a TSA? What is the end date, and what is the full service inventory?
8. Which acquired engineers are single points of knowledge, and what is the
   retention plan?
9. What is the synergy target, by mechanism, and how is it measured monthly?
10. If this business unit were divested in three years, what would we wish we had
    done differently now?
