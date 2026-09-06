# Banking as a Service (BaaS)

For platforms that let another company embed banking or payments capability
into their own product — a sponsor-bank-backed BaaS platform, an embedded
finance layer, or a core-banking/ledger system built to serve multiple
tenants. This is architecturally the hardest domain in this skill: it
combines the consistency requirements of a ledger, the multi-tenancy
requirements of a platform, and the compliance requirements of a bank, on
infrastructure the platform itself does not fully control (a sponsor bank or
banking license usually sits above it). All figures here are sourced in
`references/07-verified-facts.md`.

---

## 1. The Model, Briefly

**BaaS** = a licensed bank (or a fintech operating under one, via a
"sponsor bank" relationship) exposes core banking capability — account
opening, ledger, payments, card issuing — as an API platform that another
company's product consumes. **Embedded finance** is the customer-facing end
of the same thing: a non-bank product offering a banking feature without
becoming a bank.

**Who is the platform, technically:**

- The **BaaS provider** operates the core ledger, the compliance program
  (KYC/AML, transaction monitoring), and the regulatory relationship — the
  license is either its own or a sponsor bank's, and that distinction changes
  everything about who is liable for what.
- The **program/product company** (the BaaS provider's customer) builds the
  end-user experience and consumes the BaaS provider's APIs — it typically
  does not touch the ledger directly.

This skill's remit is the BaaS provider's own architecture — the ledger,
the multi-tenancy model, and the API surface — not the program company's
product.

---

## 2. The Ledger Is the System of Record — Choose Its Consistency Deliberately

The ledger has to be right, not just fast. A money-movement bug that
double-credits or silently drops a transaction is a different class of
incident than a slow API response.

**Google Cloud — Spanner is the proven pattern.** Current, a US challenger
bank, migrated its core member/account/wallet/gateway graph service onto
Cloud Spanner specifically for **consistent writes, horizontal scalability,
low read latency under load, and multi-region failover**. Published results:
**zero availability incidents since migration**, close to **5,000
transactions per second**, **RTO and RPO both reduced by more than 10× (RTO
now ~1 hour)**, achieved via a phased zero-downtime, zero-data-loss cutover
(migrate reads, verify, then migrate writes). Spanner's external
consistency (not just "strong consistency" — a stronger, globally-ordered
guarantee) is what makes it a credible ledger substrate without hand-rolling
distributed-transaction logic.

Source: [How Current leveraged Spanner to build a resilient platform for banking services — Google Cloud Blog, 6 Dec 2024](https://cloud.google.com/blog/products/databases/current-challenger-bank-database-resilience-spanner/)

**AWS — the ledger-specific service was retired; the current pattern is
different.** Amazon QLDB (Quantum Ledger Database), AWS's purpose-built
immutable-ledger database, **was discontinued** (announced July 2024). AWS's
own published migration path for existing ledger/audit-trail workloads is
**Amazon Aurora PostgreSQL**, using cryptographic verification patterns
layered on top rather than a dedicated ledger engine. Design a new BaaS
ledger on AWS around Aurora (or DynamoDB with transactions, for a
higher-write-throughput, more denormalized model) plus an explicit
append-only/event-sourced pattern — do not design around QLDB; it is not
available for new workloads.

Source: [Migrate an Amazon QLDB Ledger to Amazon Aurora PostgreSQL — AWS Database Blog](https://aws.amazon.com/pt/blogs/database/migrate-an-amazon-qldb-ledger-to-amazon-aurora-postgresql/)

**The pattern that holds regardless of database choice:**

- **Double-entry, not single-balance.** Every movement is two ledger entries
  (debit one account, credit another) in the same transaction — a single
  mutable "balance" field is not an audit-defensible ledger.
- **Append-only.** Entries are never updated or deleted; corrections are new
  entries that reference the one they correct.
- **Idempotency keys on every money-movement API call.** A retried request
  (client timeout, network blip, at-least-once message delivery) must be
  safely replayable without double-moving money — the idempotency key, not
  the caller's judgment, is what prevents the duplicate.
- **The saga pattern for anything spanning services.** A transfer that
  touches account service, ledger service and notification service is not
  one distributed transaction — it is a saga with compensating actions for
  each step, and the compensations are tested, not assumed to work.

---

## 3. Multi-Tenancy — Isolation Is a Spectrum, Choose Per Risk Tier

A BaaS platform serves multiple program companies from shared
infrastructure. The isolation model is a risk decision, not a default:

| Model | Isolation | Cost | Use for |
| --- | --- | --- | --- |
| **Silo** (dedicated infrastructure per tenant) | Highest | Highest — no economy of scale | A program company with its own regulatory requirement for dedicated infrastructure, or a single very large tenant |
| **Pool with logical isolation** (shared infra, tenant ID on every row/request, enforced at the data layer) | Application-enforced | Lowest | The default for most tenants — but only if the enforcement is airtight |
| **Bridge** (shared compute, tenant-dedicated data store) | Data-layer isolation, shared blast radius above it | Medium | A common middle ground — isolate the ledger's storage per tenant even when the API layer is shared |

**The failure mode that matters most:** a query that forgets the tenant-ID
filter. In a BaaS context that is not a data-leak bug, it is a "customer A
can see customer B's money" bug. Mitigate architecturally, not just by code
review — row-level security enforced by the database (Cloud SQL/Spanner
policies, Postgres RLS on Aurora), not solely by application logic, is the
defensible pattern for anything beyond a handful of tenants.

---

## 4. The API Surface and the Compliance Program Sit Together

- **KYC/AML is not bolt-on.** Account opening, transaction monitoring and
  sanctions screening are typically the sponsor bank's regulatory
  requirement flowing through to the BaaS provider's platform — the
  architecture needs a clear, auditable boundary for where a transaction is
  screened and by what, before it can be reversed or reported.
- **The API surface a program company consumes should look like
  `13-open-finance-open-banking.md` §4's pattern** — a gateway/BFF layer in
  front of the ledger, never direct ledger access — plus program-company
  scoping so one program's API keys cannot reach another program's tenant
  data (§3).
- **Card issuing, if in scope, is its own cryptographic domain.** PIN
  generation/translation and card-data tokenization go through
  `12-pci-dss.md`'s HSM-backed services (Cloud HSM/KMS, or AWS Payment
  Cryptography specifically for PIN operations) — never through
  general-purpose application code.

---

## 5. Anti-Patterns

| Anti-pattern | What goes wrong |
| --- | --- |
| A mutable "balance" column as the ledger | No audit trail of how the balance got there; unrecoverable in a dispute |
| No idempotency key on transfer APIs | A client retry double-moves money under load or network blips |
| Tenant isolation enforced only in application code | One missed `WHERE tenant_id = ?` clause is a cross-tenant money-visibility bug |
| Designing a new AWS ledger around QLDB | QLDB is discontinued; design around Aurora PostgreSQL or DynamoDB instead |
| Program company given direct database access "for reporting" | Bypasses every consent/scope control built into the API layer |
| Treating the sponsor-bank relationship as a procurement detail | The sponsor bank's regulatory exam findings become the platform's engineering backlog — get compliance and engineering in the same room early |

---

## 6. Review Checklist

1. Is the ledger append-only, double-entry, and does every money-movement
   call carry an idempotency key?
2. If on AWS: has the design explicitly moved past QLDB to a current
   database (Aurora PostgreSQL, DynamoDB), not assumed QLDB is available?
3. Is tenant isolation enforced at the data layer (row-level security or
   per-tenant storage), not only in application code?
4. Is there a saga (with tested compensating actions) for any operation
   spanning more than one service?
5. Where exactly does KYC/AML screening happen in the call path, and is it
   auditable independently of the application logs?
6. Is card/PIN cryptography routed through an HSM-backed service
   (`12-pci-dss.md`), never handled in general application code?
7. Can one program company's API credentials reach another program
   company's data under any failure mode?
