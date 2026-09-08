# ADR-NNNN: [Short, decision-oriented title — "Use X for Y," not "X Investigation"]

| Field | Value |
| --- | --- |
| Status | Proposed / Accepted / Superseded by ADR-NNNN / Deprecated |
| Date | YYYY-MM-DD |
| Deciders | [Names/roles — the people who actually own this call] |
| Enterprise strategy served | Digital Transformation / M&A / Investment Programme / GenAI Enablement — [name at least one; see `references/00-role-context.md` §2] |

---

## Context

What forced this decision. Include what you'd need to reconstruct the
constraints six months from now without asking anyone:

- **Business outcome served.** [One sentence.]
- **Latency / RTO / RPO target, and where it's measured.** [Number, unit, measurement point.]
- **Data volumes and direction.** [Egress is usually the number that matters — state it.]
- **Regulatory jurisdiction.** [Which regulator, which residency/retention obligation applies.]
- **Existing estate and contractual commitments.** [What this has to interoperate with or replace.]
- **Who operates this.** [Team, and whether it's designed to be self-served.]

## Decision

The recommendation, stated as a decision — not a menu. One sentence, then
the reasoning.

[Decision statement.]

**Why this and not the alternative:** [The trade-off in the terms it actually
turns on — cost, latency, time to deliver, operational load, lock-in.]

## Options Considered

Every option comparison carries a number — this table is not optional.

| Option | 36-month cost | Latency / RTO/RPO achieved | Resiliency tier | Lead time | Operational burden | Lock-in created |
| --- | --- | --- | --- | --- | --- | --- |
| **[Recommended] Option A** | | | | | | |
| Option B | | | | | | |
| Option C (if genuinely credible — don't pad the table) | | | | | | |

## Topology

A design that cannot be drawn is not finished. Name every attachment,
router, ASN, prefix and failure domain that matters to this decision.

```mermaid
graph LR
  %% Replace with the actual topology. Keep resource-level names, not
  %% generic boxes — "Cloud Router ASN 64512," not "Router."
```

## Resiliency Tier

State the target explicitly — don't let the reader infer it from the topology.

| Attribute | Value |
| --- | --- |
| Target availability | [e.g. 99.99%] |
| RTO | |
| RPO | |
| Failure scope survived | [Zone / region / metro / provider — say which] |
| Topology that earns it | [Cross-reference the diagram above; on both clouds the SLA is contingent on topology, not on buying the product] |

## Failure Modes

For every single point of failure the design accepts or mitigates:

| Component | What fails | Blast radius | Detection | Recovery time | Accepted or mitigated |
| --- | --- | --- | --- | --- | --- |
| | | | | | |

## Build Path

- **Terraform module boundaries:** [which module(s), from `examples/` or elsewhere, this extends or instantiates]
- **Order of operations:** [what must happen before what]
- **What must be ordered from a carrier, and its lead time:** [if applicable]
- **What is self-service vs. what needs a ticket:**

## Who Consumes This, and How

If workload teams use this directly, specify the golden path or module
interface — not just the infrastructure.

[Module name / golden path name, and how a consuming team invokes it.]

## Compliance and Regulatory Mapping

[Cite the specific regulation(s) and the control(s) that discharge them —
`references/04-security-compliance-fsi.md`, and `12-pci-dss.md` /
`13-open-finance-open-banking.md` / `14-banking-as-a-service.md` if applicable.]

## Consequences

**Positive:**
-

**Negative / accepted trade-offs:**
-

**Follow-up work created by this decision:**
-

## Open Questions and Validation Steps

What's stated as an assumption here that needs measuring before this is
load-bearing. "This needs measuring" is a more useful answer than a
confident guess — name the specific test.

-

## References

- `references/NN-*.md` §N — [what it backs]
- `references/07-verified-facts.md` §N — [the sourced number(s) this ADR relies on]
