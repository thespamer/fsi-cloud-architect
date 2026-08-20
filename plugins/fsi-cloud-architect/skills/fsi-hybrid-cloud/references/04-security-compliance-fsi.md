# Security and Compliance for Financial Applications

Regulatory obligations mapped to concrete GCP and AWS controls, plus the security
architecture patterns that survive a financial-services audit.

> Regulatory texts change. Treat this file as a map of what to verify, not as
> legal advice. Confirm current requirements with the firm's compliance function
> before relying on any specific clause.

---

## 1. The Obligations That Shape Architecture

| Regime | Scope | What it constrains architecturally |
| --- | --- | --- |
| **SEC Rule 17a-4** | US broker-dealers, books and records | Records must be preserved in a non-rewriteable, non-erasable (WORM) form for defined periods, with audit trails and the ability to produce readable copies |
| **FINRA Rule 4511** | FINRA members | General books-and-records preservation, aligned with 17a-4 formats |
| **MiFID II / RTS 25** | EU trading | Clock synchronisation and timestamp granularity — see `references/03` §6 |
| **DORA** | EU financial entities (applies since 17 Jan 2025) | ICT risk management, incident reporting, resilience testing, **third-party risk register, documented exit strategies, concentration risk** |
| **EU Data Act** | EU cloud customers | Switching and data-portability rights; reduces egress friction for exits |
| **NIS2** | EU critical/important entities | Cyber risk management and incident reporting |
| **Reg SCI** | US market infrastructure | Systems capacity, integrity, resiliency, availability; BCP/DR testing |
| **SOX** | US public companies | ITGC over financially relevant systems: access, change, operations |
| **GLBA / Safeguards Rule** | US financial institutions | Customer information protection programme |
| **PCI DSS 4.0** | Card data | Segmentation, encryption, monitoring — only if card data is in scope |
| **SOC 2 / ISO 27001, 27017, 27018** | Assurance | Client-facing evidence; drives control design and reporting |
| **LGPD** (Brazil) | Personal data | Lawful basis, data subject rights, transfer rules |
| **BACEN / CMN Res. 4.893/2021** (Brazil) | BACEN-regulated institutions | Cybersecurity policy plus requirements for contracting data processing, storage and cloud services — including notification to the regulator, contractual clauses on data access and audit, and continuity provisions. **Verify current text and timelines with compliance** |
| **MAS TRM, FFIEC, PRA/FCA outsourcing** | APAC / US / UK | Broadly parallel outsourcing and resilience expectations |

**Architectural translation:** the recurring themes are (1) immutable retention,
(2) demonstrable key custody, (3) data residency, (4) provable resilience, and
(5) a real exit path. Everything below serves one of those five.

---

## 2. Immutable Retention (17a-4 / FINRA 4511)

| Requirement | AWS | GCP |
| --- | --- | --- |
| WORM storage | **S3 Object Lock in Compliance mode** — no user, including the account root, can delete or shorten the retention period until it expires | **Bucket Lock** (bucket-level retention policy that can be locked) plus **object retention lock** for per-object control |
| Legal hold independent of retention | S3 Object Lock legal hold | Object holds |
| Audit trail | CloudTrail (data events on the bucket), S3 server access logs | Cloud Audit Logs (Data Access logs enabled), Storage bucket logs |
| Readable production | Lifecycle policy plus documented restore/export runbook | Same |
| Prevent bypass | SCP denying `s3:PutObjectRetention` downgrade, deny bucket deletion; block public access at org level | Org policy constraints, IAM deny policies, VPC Service Controls perimeter |

**Governance mode is not compliance mode.** Governance mode allows privileged
users to override retention — it does not satisfy a WORM obligation. Use
Compliance mode and be certain of the retention period first: it cannot be
shortened.

**Practical checklist:**
- Retention period set from the regulatory clock, not the ingest date, where they
  differ
- Object Lock enabled at bucket creation (it cannot be added retroactively on S3
  in the same way)
- Replication of locked objects configured and tested, with retention preserved
- Deletion attempts logged and alerted — the audit evidence is the denied attempt
- Annual restore test with documented output

---

## 3. Encryption and Key Custody

| Control | AWS | GCP |
| --- | --- | --- |
| Managed keys | KMS with customer-managed keys (CMK) | Cloud KMS with CMEK |
| Dedicated hardware | CloudHSM | Cloud HSM |
| **Keys outside the cloud provider** | External Key Store (XKS) | **Cloud EKM** |
| Key rotation | Automatic annual, or manual schedule | Automatic rotation schedule |
| Confidential compute | **Nitro Enclaves**, AMD SEV / Intel TDX instances | **Confidential VMs / Confidential GKE** |
| Envelope encryption for app secrets | Secrets Manager, Parameter Store | Secret Manager |
| In transit | TLS 1.2+, mTLS between services, MACsec/IPsec on circuits | Same |

**Key custody is the question auditors actually ask.** Decide and document
whether the firm requires keys held outside the provider (EKM/XKS) or whether
provider-held CMEK/CMK with strict IAM satisfies policy. EKM/XKS adds latency and
an availability dependency on the external HSM — model it, especially for
high-throughput encrypt/decrypt paths.

**Separation of duties:** the identity that can use a key must not be the
identity that can delete or alter its policy. Enforce with distinct IAM roles and
org-level guardrails.

---

## 4. Data Residency and Sovereignty

| Control | AWS | GCP |
| --- | --- | --- |
| Restrict where resources deploy | SCP with `aws:RequestedRegion` condition | Org policy `constraints/gcp.resourceLocations` |
| Prevent data exfiltration to other projects/accounts | VPC endpoint policies, RCPs, `aws:PrincipalOrgID` conditions | **VPC Service Controls** service perimeters |
| Sovereign controls package | AWS European Sovereign Cloud / dedicated regions | **Assured Workloads** (data residency, personnel controls, support controls) |
| Restrict support access | AWS controls per programme | Assured Workloads support controls |

**VPC Service Controls is the highest-leverage GCP control for FSI.** It creates
a perimeter around Google APIs so that even a valid credential cannot exfiltrate
data to a project outside the perimeter. Configure it early; retrofitting
perimeters onto a live estate is painful. Combine with Assured Workloads when
residency or personnel controls are mandated.

**On AWS the equivalent posture is composed**, not a single product: SCPs +
resource control policies + VPC endpoint policies + `aws:PrincipalOrgID`
conditions + Config rules. Document the composition as one control.

---

## 5. Preventive Guardrails

| Layer | AWS | GCP |
| --- | --- | --- |
| Org structure | Organizations, OUs, **Control Tower** | Organization, folders, projects |
| Preventive policy | **SCPs** (identity) and **RCPs** (resource) | **Org policy constraints**, IAM **deny policies** |
| Network policy | Security groups, NACLs, Network Firewall, VPC endpoint policies | **Hierarchical firewall policies**, Cloud NGFW |
| Detective | **Security Hub**, GuardDuty, Config, Macie, IAM Access Analyzer, Inspector | **Security Command Center**, Cloud Asset Inventory, Recommender |
| Baseline | CIS AWS Foundations Benchmark, Config conformance packs | CIS GCP Foundations Benchmark, Assured Workloads |
| Runtime | Systems Manager, EKS/ECS runtime security | GKE security posture, Binary Authorization |

**Minimum guardrail set for an FSI estate — implement these before workloads:**

1. Deny public S3 buckets / public Cloud Storage at the org level
2. Deny disabling of logging (CloudTrail / Cloud Audit Logs) in any account or project
3. Restrict deployable regions to the approved list
4. Deny root/owner API usage; require federated identity
5. Require encryption at rest with CMK/CMEK on data stores
6. Deny creation of IAM users with static access keys / service account key export
7. Require IMDSv2 (AWS) and Shielded VM (GCP)
8. Deny deletion of log sinks, KMS keys and Object Lock configurations
9. Mandatory tagging/labelling for cost centre, data classification and owner
10. Centralised, immutable log archive in a separate account/project with restricted access

---

## 6. Identity and Access

- **Federate humans from one IdP** to both clouds. Groups, not individual grants.
- **No static keys for workloads.** Use IAM roles for service accounts (IRSA) /
  instance profiles on AWS, and Workload Identity on GCP. Cross-cloud, use
  workload identity federation — see `references/01` §6.
- **Just-in-time elevation** for privileged operations, with approval and
  automatic expiry. Standing admin is a finding in every FSI audit.
- **Break-glass accounts**: two, hardware-MFA protected, credentials split and
  sealed, usage alerted in real time to the SOC, tested quarterly.
- **Access reviews**: quarterly recertification, evidence retained. This is
  usually the SOX ITGC evidence that gets sampled.
- **Segregation of duties** between who deploys, who approves and who can access
  production data.

---

## 7. Logging, Monitoring and Evidence

Design the evidence trail as a first-class system, because it is what gets
audited.

| Log type | AWS | GCP | Retention driver |
| --- | --- | --- | --- |
| Control plane API | CloudTrail (org trail, all regions) | Cloud Audit Logs — Admin Activity | Audit, forensics |
| Data access | CloudTrail data events, S3 access logs | Cloud Audit Logs — Data Access (must be explicitly enabled) | 17a-4 access trails, DLP |
| Network flow | VPC Flow Logs | VPC Flow Logs | Incident response |
| DNS | Route 53 Resolver query logs | Cloud DNS logging | Threat hunting |
| Application/transaction | Structured app logs | Structured app logs | Records rules |
| Clock offset | Custom metric from PTP/NTP client | Custom metric | MiFID II evidence |

**Rules:**
- Ship to a **dedicated logging account/project** with write-only access from
  source and no delete permission for anyone outside a break-glass path
- Apply **Object Lock / Bucket Lock** to the log archive with the regulatory
  retention period
- Enable **Data Access logs on GCP explicitly** — they are off by default and
  their absence is a common audit finding
- Define retention per log type against the specific rule that requires it, and
  record the mapping

---

## 8. Resilience and Exit (DORA and Reg SCI)

DORA moved these from paperwork to engineering requirements.

**ICT third-party risk**
- Maintain a register of information covering every ICT provider supporting a
  critical or important function, including the cloud services themselves
- Contracts must carry audit rights, incident notification, subcontracting
  transparency and termination provisions

**Concentration risk**
- Identify functions where a single provider failure is unsurvivable
- Document the assessment — regulators ask for the analysis, not just a mitigation
- Genuine multicloud for critical functions is one answer; a tested, timed
  fallback is another; "we accept the risk, here is why" with evidence is a third

**Exit strategy — the part that is actually architectural**
- A documented, **tested** plan to move a critical function off a provider within
  a stated timeframe
- Practical enablers: portable data formats (Parquet, Avro, open table formats),
  containerised workloads, IaC that is not single-provider-idiomatic where it
  need not be, and an inventory of every managed-service dependency with its
  migration path
- The EU Data Act's switching provisions reduce egress cost as an exit barrier —
  factor that into the plan rather than treating egress as prohibitive

**Resilience testing**
- Scenario-based testing including severe but plausible disruption
- For market infrastructure, capacity and stress testing against peak
- Evidence retained: what was tested, when, what failed, what was fixed

**Design consequence:** the second cloud is not decorative. Give it a real
workload — the analytics or archive tier is the natural candidate — so the exit
path is exercised continuously rather than assumed.

---

## 9. Application Security for Financial Systems

- **Threat model the data flows**, especially anywhere market data or client
  positions cross a trust boundary
- **Entitlement enforcement** as an explicit architectural component with its own
  audit log (see `references/03` §7)
- **Secrets**: no secrets in code, IaC state, container images or environment
  variables where a managed secret store is available. Scan for them in CI
- **Supply chain**: pinned dependencies, SBOM generation, signed images, Binary
  Authorization (GCP) or signature verification in the deploy pipeline
- **Change control**: every production change traceable to an approved ticket and
  a reviewed pull request — this is the SOX ITGC evidence
- **Segmentation**: production data never in non-production. If test data derives
  from production, it must be masked or synthetic, with the process documented
- **Incident response**: runbooks per scenario, with regulator-notification
  timelines built into the runbook (DORA has tight initial-notification windows)

---

## 10. Audit Readiness Checklist

Run this before an assessment or a client due-diligence review.

- [ ] Control matrix mapping each obligation to a specific technical control, with owner
- [ ] Evidence for each control that can be produced within one business day
- [ ] Immutable retention configured, with a documented and tested restore
- [ ] Key custody model documented; rotation evidenced
- [ ] Access recertification complete for the current period
- [ ] Break-glass tested, with the test logged
- [ ] Failover / DR test performed within the required period, results documented
- [ ] Third-party register current, including cloud services and subprocessors
- [ ] Exit plan documented and, for critical functions, exercised
- [ ] Clock synchronisation evidence retained for the regulated period
- [ ] Log archive integrity verifiable — no gaps, no deletions
- [ ] Known exceptions registered with compensating controls and expiry dates
