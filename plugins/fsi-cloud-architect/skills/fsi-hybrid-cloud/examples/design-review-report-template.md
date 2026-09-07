# Design Review: [System / Change Name]

| Field | Value |
| --- | --- |
| Reviewer(s) | |
| Date | YYYY-MM-DD |
| Design reviewed | [Link to the ADR / design doc under review] |
| Checklist applied | `references/06-design-review-checklists.md` §[A–O — name the sections actually relevant] |

---

## Summary

One paragraph: what this design does, and the overall verdict. State plainly
when a design is sound — don't manufacture findings to look thorough.

[Summary.]

## What This Design Does Well

Reviews that only list problems get discounted. Name the specific choices
worth keeping, not a generic compliment.

-

## Findings

Ordered by severity. Every finding names the concrete failure or cost, not
a principle, and every recommendation carries a number or a setting.

| # | Severity | Finding | Why It Matters | Recommendation |
| --- | --- | --- | --- | --- |
| 1 | Blocker | | | |
| 2 | Major | | | |
| 3 | Minor | | | |
| 4 | Observation | | | |

**Severity definitions** (for consistency across reviewers):
- **Blocker** — must be fixed before this ships. Names a failure mode that will occur, not one that might.
- **Major** — should be fixed before this ships; workable exceptions need an explicit, recorded decision.
- **Minor** — worth fixing, does not block.
- **Observation** — informational; no action required, but worth recording for the next reviewer.

## Checklist Coverage

Which sections of `references/06-design-review-checklists.md` were applied,
and the outcome of each — this is what makes the review auditable later.

| Checklist section | Applicable? | Result |
| --- | --- | --- |
| A. Requirements and Constraints | | |
| B. Connectivity and Routing | | |
| C. DNS and Identity | | |
| D. Latency and Market Data | | |
| E. Security and Compliance | | |
| F. GenAI and AI/ML Workloads | | |
| G. Resilience, DR and Exit | | |
| H. Operations and Cost | | |
| I. Enablement and Consumability | | |
| J. M&A Cloud Integration | | |
| L. PCI DSS and Payment Data | | |
| M. Open Finance and Open Banking | | |
| N. Banking as a Service and Ledger Integrity | | |
| O. Documentation and Decisions | | |

## Resiliency Tier Verification

Don't take the design doc's stated tier at face value — verify the topology
actually earns it.

| Attribute | Design claims | Reviewer verified? |
| --- | --- | --- |
| Target availability | | |
| RTO / RPO | | |
| Failure scope survived (zone / region / provider) | | |
| Topology matches the claimed tier (§ in `references/02-private-connectivity.md` or `references/09-ha-dr-patterns.md`) | | |

## Cost Sanity Check

| Claim in design | Reviewer assessment |
| --- | --- |
| 36-month total | |
| Egress modeled explicitly | |
| Double-running cost during any migration window | |

## Follow-Up Required Before Re-Review

- [ ]
- [ ]

## Sign-Off

| Outcome | Approved / Approved with conditions / Not approved |
| --- | --- |
| Conditions (if any) | |
| Re-review required? | |

## References

- `references/06-design-review-checklists.md`
- `references/07-verified-facts.md` §N — [any sourced number a finding relies on]
