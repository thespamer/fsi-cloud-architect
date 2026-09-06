# PCI DSS in the Cloud

For any workload that stores, processes or transmits cardholder data — a
payments product, a BaaS platform (`14-banking-as-a-service.md`), a merchant
settlement pipeline. PCI DSS is a **contractual** obligation (enforced by the
card brands through acquirers), not a law, but the consequences of losing
compliance — fines, increased transaction fees, loss of card-acceptance
rights — are business-ending for a payments product. All figures here are
sourced in `references/07-verified-facts.md`.

---

## 1. Scope Is the First Design Decision

The single highest-leverage architectural decision in PCI DSS is **how small
you make the Cardholder Data Environment (CDE)** — the systems that store,
process or transmit primary account numbers (PAN), plus anything connected to
or capable of impacting the CDE's security. Everything in scope must meet all
12 requirements; everything correctly segmented out of scope does not.

**Design for segmentation, not for compliance everywhere:**

- **Tokenize at the earliest possible point.** Once a PAN is replaced with a
  token, systems downstream of that point are out of scope. This is the
  single biggest scope-reduction lever available.
- **Isolate the CDE at the network layer**, not just logically. On GCP: a
  dedicated VPC or Shared VPC service project with its own firewall policy,
  no default route to the rest of the estate. On AWS: a dedicated VPC/account
  with Security Groups and NACLs enforcing least-path, ideally within its own
  OU under AWS Organizations with dedicated SCPs.
- **Treat "connected-to" scope as seriously as "in" scope.** A jump host,
  monitoring agent, or shared logging pipeline that touches the CDE pulls
  that system into scope even if it never sees a PAN.
- **P2PE (Point-to-Point Encryption)** — encrypting card data at the point of
  interaction, before it ever reaches your infrastructure — removes the
  largest possible chunk of the estate from scope. Consider it before
  building a CDE at all.

---

## 2. Google Cloud — Responsibility Split and Named Services

Google publishes a PCI DSS v4.0.1 shared-responsibility matrix. Broadly:

| Google's responsibility | Shared | Customer's responsibility |
| --- | --- | --- |
| Firewall configuration security for the underlying infrastructure; anti-spoofing by default; malware protection for GCP's own infrastructure; default encryption at rest for customer data | Network security control configuration (Google provides the firewall infrastructure; customer configures and reviews the rules); administrative access encryption (Google secures GCP platform access; customer secures its own applications and remote connections) | Configuration standards for VM instances, VPC networks and storage buckets; anti-virus on customer-managed VM instances; key management for customer-generated keys |

**Named GCP services that map directly to requirements:**

| Service | PCI DSS use |
| --- | --- |
| **Cloud KMS / Cloud HSM** | Key generation, storage and rotation (Req. 3.5–3.7) |
| **Cloud DLP** | PAN discovery and masking outside the CDE (Req. 3.2, and confirming scope boundaries) |
| **Secret Manager** | Inventory and secure storage of certificates and keys |
| **Network Intelligence Center** | Network diagram and data-flow documentation — PCI DSS explicitly requires an accurate, current network diagram |
| **Security Command Center Premium** | Malware detection and threat analysis (Req. 5, 11) |
| **Shielded VMs** | Protection against rootkits/bootkits at the instance level |
| **VPC Service Controls** | Perimeter enforcement around the CDE's data services — the same primitive used for the GenAI perimeter in `08-genai-ml-platform.md` |

Source: [Google Cloud PCI DSS v4.0.1 Shared Responsibility Matrix](https://services.google.com/fh/files/misc/gcp_pci_dss_v4_responsibility_matrix.pdf)

---

## 3. AWS — Responsibility Split and Named Services

AWS completes a Level 1 PCI DSS assessment as a Service Provider **twice a
year** and publishes its Attestation of Compliance through AWS Artifact — a
useful document to hand to your own QSA directly. AWS's own framing: AWS
manages the infrastructure that runs the services and physical/environmental
controls; the customer is responsible for security **in** the cloud — the
customer-configured systems and services launched on AWS.

**Named AWS services that map directly to requirements:**

| Service | PCI DSS use |
| --- | --- |
| **CloudHSM** | FIPS 140-2 Level 3 validated HSM for encryption key generation (Req. 3.5–3.7) |
| **AWS Payment Cryptography** | Managed HSM purpose-built for payment cryptographic operations — PIN generation, translation and verification (`TranslatePinData`, `GeneratePinData`) — for issuing/acquiring workloads specifically, distinct from general-purpose CloudHSM/KMS |
| **KMS** | General-purpose key management, AES-256 symmetric keys, access controlled via IAM |
| **Security Groups / NACLs / Network Firewall** | CDE network segmentation (Req. 1.3–1.4) — Security Groups are stateful NSCs within a VPC, NACLs are stateless NSCs at the subnet boundary |
| **GuardDuty** (Malware Protection) | Threat/intrusion detection on EC2 and containers (Req. 5.2.2, 11.5.1) |
| **Macie** | Discovers PAN or other sensitive data stored outside authorized locations (Req. 3.2) |
| **AWS Config** | Continuous configuration monitoring and drift detection (Req. 2.2, 10.7, 11.5.2, 12.5) |
| **CloudTrail** | API-activity audit trail — covers the six audit-trail details PCI DSS Req. 10.2–10.3 requires |

Source: [PCI DSS v4.0 Compliance on AWS whitepaper](https://d1.awsstatic.com/whitepapers/compliance/pci-dss-compliance-on-aws-v4-102023.pdf)

---

## 4. Network Segmentation for the CDE

This is where `01-hybrid-topology.md` and `02-private-connectivity.md` meet
PCI DSS directly:

- **The CDE gets its own VPC (or Shared VPC service project) / account**, not
  a subnet carved out of a shared one. NCC/TGW attach it, but its route table
  and firewall policy are its own, reviewed on their own cadence (PCI DSS
  requires a firewall/router rule review at least every six months).
- **PSC/PrivateLink (`02-private-connectivity.md` §10), not peering**, for
  anything the CDE needs to consume from outside its boundary — a payment
  gateway calling a tokenization service, for instance. Peering would put the
  calling system's whole network in scope-adjacent territory; a private
  endpoint scopes the exposure to one service.
- **Segmentation testing is a requirement, not a one-time design review.**
  PCI DSS Req. 11.4.5 (for service providers) mandates penetration testing of
  segmentation controls at least every six months, and after any
  segmentation-relevant change. Build this into the release pipeline for
  anything touching the CDE boundary, not into an annual calendar reminder.
- **Multi-cloud CDE spans are hard to justify.** If the CDE has to reach both
  GCP and AWS, the Cross-Cloud Interconnect / AWS Interconnect path
  (`02-private-connectivity.md` §1) is in scope for the same segmentation and
  testing obligations as everything else — treat it as CDE network, not as
  ordinary hybrid transit.

---

## 5. Logging, Key Custody and Retention

- **Immutable audit logs.** The same WORM/retention-lock pattern used for
  17a-4/FINRA (`04-security-compliance-fsi.md` §2) applies to PCI DSS Req.
  10's audit trail requirement — Object Lock Compliance mode / Bucket Lock,
  not just access controls.
- **Key custody separation.** Whoever can approve a key rotation or deletion
  should not be the same person who can access decrypted cardholder data —
  PCI DSS's dual-control and split-knowledge requirements for cryptographic
  key management (Req. 3.6/3.7) map directly onto IAM role separation, not
  just KMS configuration.
- **Retention minimization cuts both ways.** Regulatory retention rules push
  toward keeping data; PCI DSS Req. 3.2 pushes toward not storing PAN longer
  than a defined, documented business need, and never storing sensitive
  authentication data (full track data, CVV, PIN) after authorization, full
  stop. Reconcile these explicitly per data element — do not apply one
  blanket retention policy to both cardholder data and regulatory records.

---

## 6. Common Failure Modes

| Failure mode | What goes wrong |
| --- | --- |
| CDE scope creep via a shared logging/monitoring agent | The monitoring fleet is now in scope, and nobody scoped it that way |
| Tokenizing "later" | The whole ingestion path stays in scope indefinitely; tokenize at first touch |
| Treating the segmentation test as an annual audit checkbox | Fails Req. 11.4.5's every-six-months-and-after-change cadence |
| One VPC/account for CDE and non-CDE workloads, separated "by security group" | Security-group-only isolation is not the segmentation control assessors expect; use network-level isolation |
| PSC/PrivateLink service exposed without endpoint policies restricting the consumer | Scopes the wrong thing — anyone who can reach the endpoint can call the service |
| Storing full PAN in logs "for debugging" | Automatic Req. 3.2 violation; mask or tokenize before it ever reaches a log sink |

---

## 7. Review Checklist

1. Is the CDE boundary drawn at the network layer (dedicated VPC/account),
   not just logically?
2. Where is the earliest point PAN is tokenized, and could it be earlier?
3. Is segmentation penetration-tested at least every six months and after
   every CDE-boundary change?
4. Does anything "connected to" the CDE (logging, monitoring, jump hosts)
   also sit inside the assessed scope?
5. Is cryptographic key management split-knowledge/dual-control, not just
   access-controlled?
6. Does the audit log retention use an immutable/WORM mechanism?
7. Is sensitive authentication data (CVV, PIN, full track data) ever stored
   post-authorization? It should never be, anywhere.
8. If the CDE spans both clouds, is the cross-cloud path itself in the
   assessed scope?
