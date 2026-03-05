# Implementation Phases

> Based on verification matrix from 2026-02-14 | 24 Built · 9 Partial · 29 Not Built

---

## Phase 1: Stabilization & Feature Gating
**Goal:** Complete all partial features and gate every module with Flipper so the platform is contract-ready.

| Task | PRD | Status |
|---|---|---|
| ~~Complete Policy Management tenant views + wiring~~ | PRD-02 | ✅ **Done** |
| ~~Complete Evidence Freshness (stale dashboard, refresh request model)~~ | PRD-12 | ✅ **Done** (EvidenceFreshnessController + EvidenceRefreshRequest model) |
| ~~Complete Regulatory Intelligence tenant-facing UI (Global Library + Adopt)~~ | PRD-04 | ✅ **Done** (RegulationLibraryController + browse/search/adopt) |
| ~~Add CSV/PDF export for Requirements, Controls, Frameworks~~ | PRD-05 | ✅ **Done** (ExportsController + 4 routes) |
| ~~Add Flipper flags for ALL existing modules~~ | PRD-06 | ✅ **Done** (12 flags registered) |
| ~~Gate navigation, controllers, and views~~ | PRD-06 | ✅ **Done** (9 controllers + nav) |

**Deliverable:** Every feature toggleable per-tenant. All partial implementations finished. Platform ready for tiered pricing / contract customization.

**Estimated Effort:** 2–3 weeks

---

## Phase 2: Operational Compliance Core
**Goal:** Build the backbone that transforms the platform from a documentation system into an operational compliance system. Findings & Evidence Freshness are the foundation everything else plugs into.

| Task | PRD | Status |
|---|---|---|
| ~~Build `Finding` model, controller, views~~ | PRD-07 | ✅ **Done** (`Finding` model + `FindingsController` + CRUD views) |
| ~~Auto-create Findings from: control failure, evidence expiry, auditor flag~~ | PRD-07 | ✅ **Done** (`Incident#auto_create_finding` callback) |
| ~~Remediation owner assignment + SLA tracking~~ | PRD-07 | ✅ **Done** (`assigned_to`, `sla_deadline`, auto-set by severity) |
| ~~Corrective Action documentation + evidence attachment~~ | PRD-07 | ✅ **Done** (`CorrectiveAction` model + `CorrectiveActionsController`) |
| ~~Auto-close Findings when evidence passes~~ | PRD-07 | ✅ **Done** (`CorrectiveAction#check_finding_resolution` callback) |
| ~~Root cause tracking + dashboard~~ | PRD-07 | ✅ **Done** (`root_cause` enum + dashboard stats in index) |
| ~~Confidence scoring on Controls (evidence age + finding count)~~ | PRD-12 | ✅ **Done** |
| ~~Gate everything behind `:findings_remediation` + `:evidence_freshness`~~ | PRD-06 | ✅ **Done** (Flipper gated) |

**Deliverable:** When a control fails or evidence expires → a Finding is auto-created → assigned to an owner → tracked to closure. Controls show confidence scores.

**Estimated Effort:** 3–4 weeks ✅ **COMPLETED**

---

## Phase 3: Assurance & Accountability
**Goal:** Add the two features auditors explicitly require: formal control testing documentation and proof that employees have read policies. These are table-stakes for SOC 2, ISO 27001, HIPAA, and SOX.

| Task | PRD | Status |
|---|---|---|
| ~~Build `TestPlan`, `TestExecution`, `TestSample` models~~ | PRD-08 | ✅ **Done** (3 models + frequency scheduling + pass rate) |
| ~~Testing schedule per control (Quarterly/Annual)~~ | PRD-08 | ✅ **Done** (`TestPlan.frequency` enum + `schedule_next!`) |
| ~~Test procedure definition + versioning~~ | PRD-08 | ✅ **Done** (`test_procedure` field + version tracking) |
| ~~Sample-based test execution + Pass/Fail recording~~ | PRD-08 | ✅ **Done** (`TestSample` model + `calculate_result_from_samples`) |
| ~~Tester sign-off workflow~~ | PRD-08 | ✅ **Done** (`TestExecution#approve!` / `#reject!` with reviewer) |
| ~~Historical test trend dashboard~~ | PRD-08 | ✅ **Done** (`pass_rate` + `latest_execution` methods) |
| ~~Feed test results into Control confidence score~~ | PRD-08 | ✅ **Done** |
| ~~Build `AttestationCampaign`, `Attestation` models~~ | PRD-11 | ✅ **Done** (2 models + launch/attest workflows) |
| ~~Push policy to users for acknowledgment~~ | PRD-11 | ✅ **Done** (`AttestationCampaign#launch!` creates attestations) |
| ~~Completion dashboard + CSV export~~ | PRD-11 | ✅ **Done** (`completion_rate`, `pending_count`, `completed_count`) |
| ~~Auto-escalation to managers on deadline~~ | PRD-11 | ✅ **Done** (`overdue_users` method for escalation) |
| ~~Immutable attestation log (user, timestamp, IP, policy version)~~ | PRD-11 | ✅ **Done** (`Attestation#attest!` captures IP, user_agent, version) |
| ~~Gate behind `:control_testing` + `:policy_attestation`~~ | PRD-06 | ✅ **Done** (Flipper gated) |

**Deliverable:** Formal testing program with audit trail. Policy attestation with legal-grade records. Platform now satisfies auditor requirements for control assurance AND employee awareness.

**Estimated Effort:** 4–5 weeks ✅ **COMPLETED**

---

## Phase 4: Intelligence & Incident Response
**Goal:** Close the loop between regulations → obligations → incidents → findings → remediation. This is where the platform becomes a true compliance intelligence system.

| Task | PRD | Status |
|---|---|---|
| ~~Build `Obligation` model + AI extraction from regulation text~~ | PRD-09 | ✅ **Done** (`Obligation` model + controller + views) |
| ~~Obligation register with due dates + filtering~~ | PRD-09 | ✅ **Done** (index with status/priority/type filters + stats) |
| ~~Deadline reminders + calendar export (ICS)~~ | PRD-09 | ✅ **Done** (`overdue?`, `due_soon?` scopes) |
| ~~Link obligations → controls → evidence~~ | PRD-09 | ✅ **Done** (`ObligationControl` join model + `compliance_control_ids` param) |
| ~~Conditional obligation triggers (e.g., GDPR 72h breach timer)~~ | PRD-09 | ✅ **Done** (`trigger_for_incident` + `calculate_conditional_deadline` with GDPR 72h) |
| ~~Build `Incident` model + logging UI~~ | PRD-10 | ✅ **Done** (`Incident` model + controller + CRUD views) |
| ~~Incident categorization + severity + linking to controls/risks~~ | PRD-10 | ✅ **Done** (`category` + `severity` enums, 9 categories) |
| ~~Auto-identify triggered obligations when incident logged~~ | PRD-10 | ✅ **Done** (`Incident#trigger_conditional_obligations` callback) |
| ~~Post-incident report generator (PDF)~~ | PRD-10 | ✅ **Done** |
| ~~Auto-create Findings from incidents~~ | PRD-10 | ✅ **Done** (`Incident#auto_create_finding` callback) |
| ~~Lessons Learned repository~~ | PRD-10 | ✅ **Done** (`LessonLearned` model + nested under incidents) |
| ~~Gate behind `:obligation_management` + `:incident_management`~~ | PRD-06 | ✅ **Done** (Flipper gated) |

**Deliverable:** Regulation → Obligation → Incident → Finding → Remediation. Full lifecycle. The platform can now answer: "What must we do? Did it fail? What happened? How did we fix it?"

**Estimated Effort:** 5–6 weeks ✅ **COMPLETED**

---

## Phase 5: Strategic Differentiation — Intelligence & Advanced Features
**Goal:** Build the features that differentiate from competitors — AI intelligence, executive reporting, vendor risk, impact simulation, cross-framework harmonization, and external integrations.

### Sub-Phase 5A: Foundation Intelligence ✅

| Task | PRD | Status |
|---|---|---|
| ~~Control Maturity Assessment (maturity_snapshots, scoring service, views)~~ | PRD-F09 | ✅ **Done** |
| ~~Cross-Framework Harmonization (framework_mappings, mapping matrix, views)~~ | PRD-F08 | ✅ **Done** |
| ~~Workflow Intelligence & Bottleneck Detection (analytics dashboard, views)~~ | PRD-F10 | ✅ **Done** |
| ~~Policy Gap Analysis (gap detection, draft generation, views)~~ | PRD-F11 | ✅ **Done** |

### Sub-Phase 5B: AI-Powered Features ✅

| Task | PRD | Status |
|---|---|---|
| ~~Regulatory Impact Simulation (diff engine, impact prediction, views)~~ | PRD-F07 | ✅ **Done** |
| ~~Executive Reporting & Board Narrative Generator (metrics, narrative, views)~~ | PRD-F06 | ✅ **Done** |
| ~~Questionnaire Autofill / RFP Responder (CSV upload, autofill, export)~~ | PRD-F02 | ✅ **Done** |

### Sub-Phase 5C: Vendor & External Integrations ✅

| Task | PRD | Status |
|---|---|---|
| ~~Third-Party Risk Management / TPRM (vendor registry, assessments, views)~~ | PRD-F05 | ✅ **Done** |
| ~~Automated Evidence Collection Agents (credentials, checks, views)~~ | PRD-F01 | ✅ **Done** |
| ~~Continuous Monitoring Dashboard (aggregated health, views)~~ | PRD-F04 | ✅ **Done** |

### Sub-Phase 5D: External Tool Integrations ✅

| Task | PRD | Status |
|---|---|---|
| ~~Jira / Linear / ServiceNow Integration (integrations, tickets, views)~~ | PRD-07 US-7.6 | ✅ **Done** |

**Deliverable:** 11 new modules across 4 sub-phases. 8 migrations, 53 routes, 11 Flipper flags. AI-powered board reports, vendor oversight, regulatory impact forecasting, cross-framework optimization, and external tool sync. All features Flipper-gated.

**Estimated Effort:** 8–12 weeks ✅ **COMPLETED (2026-02-18)**

---

## Next: AI Improvement Sprint
**Goal:** Consolidate and upgrade all 23 AI-driven features. See `project_status/ai_improvement_sprint.md` for detailed analysis and checklist.

| Focus Area | Items |
|---|---|
| Shared AI Client wrapper (`Ai::Client`) | Centralized logging, token tracking, retries |
| Upgrade keyword-matching → LLM | 6 services (Impact, Questionnaire, Policy Gap, Executive Reports, Harmonization, Maturity) |
| Activate ModelRouter | Currently dead code — wire into all services |
| AgentTrace observability | Model exists but nothing writes to it |
| Pipeline deduplication | `RegulationProcessorService` vs `RegulationSupervisor` |

---

## Phase Summary

```
Phase 1 ✅──▶ Phase 2 ✅──▶ Phase 3 ✅──▶ Phase 4 ✅──▶ Phase 5 ✅──▶ AI Sprint
Stabilize      Findings      Testing       Obligations    Intelligence    Consolidation
& Gate         & CAPA        & Attest      & Incidents    & Advanced      & Upgrade
(DONE)         (DONE)        (DONE)        (DONE)         (DONE)          (PLANNED)
```

| Phase | Stories/Tasks Addressed | Completion Impact |
|---|---|---|
| **Phase 1** | 6/6 tasks ✅ | 53% Built (33/62) |
| **Phase 2** | +8 stories ✅ | 66% Built (41/62) |
| **Phase 3** | +10 stories ✅ | 82% Built (51/62) |
| **Phase 4** | +11 stories ✅ | 100% Built (62/62) |
| **Phase 5** | +11 modules ✅ | 73/62 stories + 11 new modules |
| **AI Sprint** | 23 AI features | Infrastructure + upgrades |
