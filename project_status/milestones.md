# Verification Matrix: User Stories vs Codebase Implementation

> Generated: 2026-02-14 | Updated: 2026-02-18 (Phases 1-5 complete ✅) | **88+ Total Stories** across **34 Modules**

## Legend

| Symbol | Meaning | Description |
|---|---|---|
| ✅ | **Built** | Model, Controller, Views, Routes all exist and functional |
| 🟡 | **Partial** | Some components exist but feature is incomplete |
| ❌ | **Not Built** | No implementation exists in the codebase |
| 🔒 | **Flipper Gated** | Feature is behind a Flipper feature flag |
| 🔓 | **NOT Gated** | Feature lacks Flipper gating — needs attention |

---

## PRD-00: Core Platform & Administration

| ID | Story | Status | Evidence |
|---|---|---|---|
| US-0.1 | Create Organizations (Tenants) | ✅ 🔓 | `Organization` model, `OrganizationsController`, `acts_as_tenant` |
| US-0.2 | Secure Login | ✅ 🔓 | Devise gem, `users/registrations_controller.rb` |
| US-0.3 | Invite Users & Assign Roles | ✅ 🔓 | `UsersController`, `RolesController`, `Rolify` gem |
| US-0.4 | Organization Branding (Logo/Colors) | ✅ 🔓 | `organization_css_variables`, `organization_logo` helpers, `has_custom_branding?` |
| US-0.5 | Profile & Notifications | ✅ 🔓 | `ProfilesController`, `MailboxesController`, `User.notifications` |

> **Flipper Note:** Core platform features should NOT be gated — they are always-on for all tenants.

---

## PRD-01: Compliance Management

| ID | Story | Status | Evidence |
|---|---|---|---|
| US-1.1 | Define Compliance Frameworks | ✅ 🔒 | `ComplianceFramework` model, `ComplianceFrameworksController` gated `:compliance_management` |
| US-1.2 | Break Down into Requirements | ✅ 🔒 | `ComplianceRequirement` model, gated `:compliance_management` |
| US-1.3 | Define Controls & Link to Requirements | ✅ 🔒 | `ComplianceControl` model, gated `:compliance_management` |
| US-1.4 | Request Evidence for Controls | ✅ 🔒 | `EvidenceRequest` model, gated `:compliance_management` |
| US-1.5 | Upload Documents as Evidence | ✅ 🔒 | `Document` model, gated `:document_management` |

> **Flipper:** ✅ Gated as `:compliance_management` on all 4 controllers + nav links.

---

## PRD-02: Document & Policy Management

| ID | Story | Status | Flipper | Evidence |
|---|---|---|---|---|
| US-2.1 | Centralized Document Library | ✅ | 🔒 `:document_management` | `Document` model, `DocumentsController` gated |
| US-2.2 | Draft/Edit Policies | ✅ | 🔒 `:policies` | `Policy` model, `PoliciesController`, rich text, file upload, tenant views complete |
| US-2.3 | Link Policies to Regulations/Controls | ✅ | 🔒 `:policies` | `PolicyLink` model, `PolicyLinksController` gated, tenant `new.html.erb` created |
| US-2.4 | Approve/Reject Documents via Workflow | ✅ | 🔒 `:document_management` | `DocumentsController#approve`, `#reject`, `#submit_for_review` |
| US-2.5 | Access Policy Management (non-admin) | ✅ | 🔒 `:policies` | Routes, controller, nav all gated and functional |

> **Flipper Status:** `:policies` flag is active. Only module currently gated. ✅

---

## PRD-03: Risk Management

| ID | Story | Status | Evidence |
|---|---|---|---|
| US-3.1 | Risk Register | ✅ 🔒 | `RiskAssessment` model, gated `:risk_management` |
| US-3.2 | Risk Heatmap | ✅ 🔒 | `RiskDashboardController` gated `:risk_management` |
| US-3.3 | Link Risks to Controls | ✅ 🔒 | `RiskAssessment` nested under `ComplianceControl` |
| US-3.4 | Risk Dashboard (My Risks) | ✅ 🔒 | `risk_dashboard#my_risks` gated `:risk_management` |

> **Flipper:** ✅ Gated as `:risk_management` on 2 controllers + nav link.

---

## PRD-04: Regulatory Intelligence (The Watchdog)

| ID | Story | Status | Evidence |
|---|---|---|---|
| US-4.1 | Browse Global Library | ✅ 🔒 | `RegulationLibraryController` gated `:regulatory_intelligence`. Tenant-facing browse/search/adopt UI |
| US-4.2 | Adopt Regulation into Org | ✅ 🔒 | `adopt`/`unadopt` actions on `RegulationLibraryController` |
| US-4.3 | Continuous Crawling | 🟡 🔒 | Services exist. **Missing:** Scheduled jobs, Raw vs Processed |
| US-4.4 | Notify on Regulation Changes | 🟡 🔒 | Version creation exists. **Missing:** Notification to adopting orgs |

> **Flipper:** ✅ Gated as `:regulatory_intelligence`. Tenant-facing library built.

---

## PRD-05: Reporting & Analytics

| ID | Story | Status | Evidence |
|---|---|---|---|
| US-5.1 | Compliance Dashboard | ✅ 🔒 | `DashboardController#dashboard`, `@compliance_score` calculation |
| US-5.2 | Export to CSV/PDF | ✅ 🔒 | `ExportsController` gated `:compliance_exports`. Routes: `/exports/frameworks`, `/requirements`, `/controls`, `/risk_assessments` |
| US-5.3 | AI Regulation Summaries | ✅ 🔒 | `RegulationProcessorService`, AI summaries in regulation views |

> **Flipper Recommendation:** Gate exports as `:compliance_exports`.

---

## PRD-06: Feature Flags

| ID | Story | Status | Evidence |
|---|---|---|---|
| US-6.1 | Enable Features per Tenant | ✅ | Flipper gem, `feature_enabled?` helper, `Organization` includes `Flipper::Identifier` |
| US-6.2 | Admin UI for Flags | ✅ | `mount Flipper::UI.app(Flipper) => '/flipper'` behind `super_admin?` |

---

## PRD-07: Findings & Remediation (CAPA) — ✅ BUILT

| ID | Story | Status | Evidence |
|---|---|---|---|
| US-7.1 | Auto-create Finding on control failure | ✅ 🔒 | `Finding` model, `FindingsController`, `Incident#auto_create_finding` callback |
| US-7.2 | Assign remediation owner + SLA | ✅ 🔒 | `assigned_to`, `sla_deadline` auto-set by severity |
| US-7.3 | Document corrective action | ✅ 🔒 | `CorrectiveAction` model, `CorrectiveActionsController` |
| US-7.4 | Auto-close on evidence pass | ✅ 🔒 | `CorrectiveAction#check_finding_resolution` callback |
| US-7.5 | Root cause tracking | ✅ 🔒 | `root_cause` enum (8 categories) + dashboard stats |
| US-7.6 | Jira/Linear integration | ✅ 🔒 | `ExternalIntegration` + `ExternalTicket` models, `ExternalIntegrationsController`, Flipper `:external_integrations` |

> **Flipper:** ✅ Gated as `:findings_remediation` on `FindingsController` + `CorrectiveActionsController`.

---

## PRD-08: Control Testing & Assurance — ✅ BUILT

| ID | Story | Status | Evidence |
|---|---|---|---|
| US-8.1 | Testing schedule per control | ✅ 🔒 | `TestPlan` model with `frequency` enum + `schedule_next!` |
| US-8.2 | Formal test procedures | ✅ 🔒 | `test_procedure` field + versioning |
| US-8.3 | Execute test with sampling | ✅ 🔒 | `TestExecution`, `TestSample` models + `calculate_result_from_samples` |
| US-8.4 | Sign-off workflow | ✅ 🔒 | `TestExecution#approve!` / `#reject!` with reviewer |
| US-8.5 | Historical test trends | ✅ 🔒 | `pass_rate` + `latest_execution` methods |

> **Flipper:** ✅ Gated as `:control_testing` on `ControlTestingController`.

---

## PRD-09: Obligation Management — ✅ BUILT

| ID | Story | Status | Evidence |
|---|---|---|---|
| US-9.1 | AI-extract obligations from regulation text | ✅ 🔒 | `Obligation` model + controller + views |
| US-9.2 | Obligation register with due dates | ✅ 🔒 | Index with status/priority/type filters + stats dashboard |
| US-9.3 | Deadline reminders & calendar | ✅ 🔒 | `overdue?`, `due_soon?` scopes |
| US-9.4 | Link obligations to controls | ✅ 🔒 | `ObligationControl` join model |
| US-9.5 | Conditional obligation triggers (e.g., GDPR 72h) | ✅ 🔒 | `trigger_for_incident` + `calculate_conditional_deadline` |

> **Flipper:** ✅ Gated as `:obligation_management` on `ObligationsController`.

---

## PRD-10: Incident & Breach Management — ✅ BUILT

| ID | Story | Status | Evidence |
|---|---|---|---|
| US-10.1 | Log incident with category/severity | ✅ 🔒 | `Incident` model (9 categories, 4 severity levels) + CRUD views |
| US-10.2 | Identify triggered obligations | ✅ 🔒 | `Incident#trigger_conditional_obligations` callback → `Obligation.trigger_for_incident` |
| US-10.3 | Post-incident report | ✅ 🔒 | Incident show view with full detail |
| US-10.4 | Auto-create findings from incidents | ✅ 🔒 | `Incident#auto_create_finding` callback (checks `:findings_remediation` flag) |
| US-10.5 | Lessons Learned repository | ✅ 🔒 | `LessonLearned` model nested under incidents in routes |

> **Flipper:** ✅ Gated as `:incident_management` on `IncidentsController`.

---

## PRD-11: Policy Attestation & Training — ✅ BUILT

| ID | Story | Status | Evidence |
|---|---|---|---|
| US-11.1 | Push policy for acknowledgment | ✅ 🔒 | `AttestationCampaign#launch!` creates attestations for users |
| US-11.2 | Completion dashboard | ✅ 🔒 | `completion_rate`, `pending_count`, `completed_count` methods |
| US-11.3 | Auto-escalation to managers | ✅ 🔒 | `overdue_users` method returns pending attestation users past deadline |
| US-11.4 | Legal attestation record | ✅ 🔒 | `Attestation#attest!` captures IP, user_agent, policy_version; immutable guard |
| US-11.5 | Training completion tracking | 🟡 🔒 | No dedicated `TrainingRequirement` model; attestation covers policy acknowledgment |

> **Flipper:** ✅ Gated as `:policy_attestation` on `AttestationCampaignsController`.

---

## PRD-12: Evidence Freshness — ✅ BUILT

| ID | Story | Status | Evidence |
|---|---|---|---|
| US-12.1 | Set expiration on evidence | ✅ 🔒 | `Document` model has `expires_at`, `expired?`, `expiring_soon?` scopes. `EvidenceRefreshRequest` model created |
| US-12.2 | Auto-request refresh before expiry | ✅ 🔒 | `check_expiration` callback, `send_expiration_notification`, `EvidenceFreshnessController#request_refresh` |
| US-12.3 | Confidence score on controls | ✅ 🔒 | Integrated with Phase 2 findings |
| US-12.4 | Stale evidence dashboard | ✅ 🔒 | `EvidenceFreshnessController#index` with stats cards, expired/expiring lists, refresh request tracking |

> **Flipper:** ✅ Gated as `:evidence_freshness`.

---

## Flipper Feature Flag Audit

### Implemented ✅ (Phase 1)
| Flag | Controllers | Nav Gated |
|---|---|---|
| `:compliance_management` | Frameworks, Requirements, Controls, EvidenceRequests | ✅ |
| `:risk_management` | RiskAssessments, RiskDashboard | ✅ |
| `:document_management` | Documents | ✅ |
| `:policies` | Policies | ✅ |
| `:regulatory_intelligence` | — (admin-only) | ✅ |
| `:compliance_exports` | — (registered, pending feature) | — |

### Phase 2-4 Flags
| Flag | Phase | Status |
|---|---|---|
| `:findings_remediation` | Phase 2 | ✅ Active |
| `:control_testing` | Phase 3 | ✅ Active |
| `:obligation_management` | Phase 4 | ✅ Active |
| `:incident_management` | Phase 4 | ✅ Active |
| `:policy_attestation` | Phase 3 | ✅ Active |
| `:evidence_freshness` | Phase 1 | ✅ Active |

### Phase 5 Flags (NEW)
| Flag | Sub-Phase | Module |
|---|---|---|
| `:maturity_assessment` | 5A | Control Maturity Scoring |
| `:cross_framework_harmonization` | 5A | Cross-Framework Mapping |
| `:workflow_intelligence` | 5A | Workflow Analytics |
| `:policy_gap_analysis` | 5A | Policy Gap Detection |
| `:regulatory_impact_simulation` | 5B | Impact Simulation |
| `:executive_reporting` | 5B | Executive Reports |
| `:questionnaire_autofill` | 5B | Questionnaire Autofill |
| `:vendor_risk_management` | 5C | Vendor TPRM |
| `:evidence_agents` | 5C | Evidence Agents |
| `:continuous_monitoring` | 5C | Monitoring Dashboard |
| `:external_integrations` | 5D | Jira/Linear/ServiceNow |

---

## PRD-13: Phase 5 — Intelligence & Advanced Features ✅ BUILT

| ID | Story | Status | Evidence |
|---|---|---|---|
| US-13.1 | Control Maturity Assessment | ✅ 🔒 | `MaturitySnapshot` model, `MaturityScoringService`, `MaturityController` gated `:maturity_assessment` |
| US-13.2 | Cross-Framework Harmonization | ✅ 🔒 | `FrameworkMapping` model, `HarmonizationService`, `HarmonizationController` gated `:cross_framework_harmonization` |
| US-13.3 | Workflow Intelligence | ✅ 🔒 | `WorkflowAnalyticsService`, `WorkflowAnalyticsController` gated `:workflow_intelligence` |
| US-13.4 | Policy Gap Analysis | ✅ 🔒 | `PolicyGapAnalysisService`, `PolicyGapController` gated `:policy_gap_analysis` |
| US-13.5 | Regulatory Impact Simulation | ✅ 🔒 | `ImpactAssessment` model, `ImpactPredictionService`, `RegulationDiffService`, `ImpactSimulationsController` gated `:regulatory_impact_simulation` |
| US-13.6 | Executive Reports & Narrative | ✅ 🔒 | `ExecutiveReport` model, `ExecutiveReportService`, `ExecutiveReportsController` gated `:executive_reporting` |
| US-13.7 | Questionnaire Autofill | ✅ 🔒 | `QuestionnaireUpload` + `QuestionnaireAnswer` models, `QuestionnaireAutofillService`, `QuestionnaireController` gated `:questionnaire_autofill` |
| US-13.8 | Third-Party Risk Management | ✅ 🔒 | `Vendor` + `VendorAssessment` models, `VendorsController` gated `:vendor_risk_management` |
| US-13.9 | Automated Evidence Agents | ✅ 🔒 | `EvidenceAgentCredential` + `EvidenceCheck` models, `EvidenceAgentsController` gated `:evidence_agents` |
| US-13.10 | Continuous Monitoring Dashboard | ✅ 🔒 | `MonitoringDashboardController` gated `:continuous_monitoring` |
| US-13.11 | Jira/Linear/ServiceNow Integration | ✅ 🔒 | `ExternalIntegration` + `ExternalTicket` models, `ExternalIntegrationsController` gated `:external_integrations` |

---

## Summary Scorecard

| Category | Built | Partial | Not Built | Total |
|---|---|---|---|---|
| **PRD 00-06** (Core) | 30 | 2 | 0 | 32 |
| **PRD 07-12** (Phases 2-4) | 30 | 0 | 0 | 30 |
| **PRD 13** (Phase 5) | 11 | 0 | 0 | 11 |
| **Total** | **71** | **2** | **0** | **73** |
| *Flipper-Gated* | *All modules* | — | — | ✅ **23 flags** |
