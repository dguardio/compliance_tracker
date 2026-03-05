# Compliance Management Platform - TODO

## Project Status Overview

### ✅ **Completed Features**
- **Multi-tenancy** with organizations, departments, teams, and units
- **User management** with roles and permissions (global and organization-specific)
- **Document management** with comprehensive preview functionality (PDF, Word, Excel, PowerPoint, images, text, CSV)
- **Compliance framework** structure (frameworks, requirements, controls)
- **Risk assessment** with register, heatmap, and control linking
- **Provider management** system (platform-wide and organization-specific)
- **Findings & Remediation (CAPA)** with auto-creation, SLA tracking, corrective actions
- **Control Testing & Assurance** with test plans, sampling, sign-off workflows
- **Obligation Management** with AI extraction, conditional triggers (GDPR 72h)
- **Incident & Breach Management** with obligation triggering, auto-findings, lessons learned
- **Policy Attestation** with campaign management, immutable legal records
- **Evidence Freshness** with expiration tracking, refresh requests
- **Phase 5 Intelligence** (11 modules): Maturity, Harmonization, Workflow Intelligence, Policy Gap, Impact Simulation, Executive Reports, Questionnaire Autofill, Vendor TPRM, Evidence Agents, Monitoring Dashboard, Jira/Linear/ServiceNow Integration
- **23 Flipper feature flags** gating all modules
- **AI Stack**: `ruby_llm` gem with Google Gemini (`gemini-2.0-flash`, `text-embedding-004`) — 17 active AI services + 6 upgrade candidates

### 🔧 **Recently Fixed Issues**
- Database schema mismatches between seed file and models
- Role management (global vs organization-specific roles)
- Permission creation with valid actions
- Provider model with optional organization_id
- Document generation in seed file
- Role display and super admin access
- Active Storage host configuration
- Document preview URL generation
- Workflow Editor `this` context issue (fixed by using arrow functions)
- **Active Tables (Tabular Interface)**: Implemented dynamic table view for regulations with custom AI-extracted columns.
- **Organization Regulation Management**: Added ability for organizations to manage their own regulation library (`/admin/organization_regulations`).
- **Inline Custom Column Creation**: Added modal for creating custom columns directly within Active Tables.
- **Auto-Assignment**: Updated auto-assignment logic to work with organization regulation management and show "System" added regulations.
- **Joyful UI Refactor**: Redesigned "Add Regulation" view (`available.html.erb`) with organization-branded gradients, modern cards, and tagify filters. Verified and reverted global header changes per feedback.
- **Neighbor Gem Stability**: Verified `Regulation.has_neighbors` availability and resolved potential transient 500 errors.

---

## 🚀 **Refined Ingestion Pipeline Plan**

This plan focuses on implementing the "Golden Source" and "Intelligence Layer" strategy.

### **Phase 1: Refined Ingestion Engine (Current Focus)**
*Goal: Upgrade the ingestion engine to support generic APIs and enhanced AI segmentation.*
- [x] **Generic API Scraper:**
    - [x] Implement `scrape_api` in `RegulatoryScraperService` to handle JSON sources.
    - [x] Add configuration in `RegulatoryDataSource` for mapping API fields (results, title, url).
    - [x] Support basic pagination strategies (page number, offset).
- [x] **Intelligence Layer (Segmentation):**
    - [x] Update `RegulationProcessorService` to segment full text into individual "Requirements".
    - [x] Configure LLM to extract "Obligations" (Actions) and "Entity Types" (Applicability).
- [x] **Data Drift Resilience:**
    - [x] Implement checks for `effective_date` and `status` changes to handle versioning.

### **Phase 2: Ingestion Capabilities Testing**
*Goal: Ensure the existing ingestion connections work accurately and harden their implementations while strictly managing token costs.*
- [ ] **Verify Seeded Sources:** Check the functionality of existing `RegulatoryDataSource` records (SEC API, SEC RSS, OCC Web Scraper, Internal API).
- [ ] **Cost-Controlled Testing:** Implement and use a strict `limit` parameter when testing to process only a very small number of regulations (e.g., 1-3) to prevent excessive LLM token spend.
- [ ] **Harden Implementations:** Address any parsing errors, unhandled edge cases, or robustness issues discovered during testing.

### **Phase 3: Advanced Intelligence & Standardization**
*Goal: Improve accuracy and interoperability.*
- [ ] **Legal-BERT Integration:** Explore fine-tuning BERT models for better classification of "Risk" and "Topic".
- [ ] **Akoma Ntoso Mapping:** Map internal data models to LegalDocML standards.

### **Phase 4: Commercial Expansion (Future)**
*Goal: Scale global coverage.*
- [ ] **vLex Integration:** Evaluate licensing **vLex Iceberg API** for global jurisdiction coverage.
- [ ] **Juriscraper:** Consider introducing Python/Juriscraper for complex non-API sources.


---

## 🛠 **Technical Debt & Improvements**

### **Performance & Scalability**
- [ ] Implement database query optimization
- [ ] Add caching strategies (Redis)
- [ ] Implement background job processing (Sidekiq)
- [ ] Add database indexing optimization
- [ ] Implement API response caching

### **Security Enhancements**
- [ ] Add comprehensive audit logging
- [ ] Implement data encryption at rest
- [ ] Add API security enhancements
- [ ] Implement advanced authentication
- [ ] Add security monitoring and alerts

### **Testing & Quality Assurance**
- [ ] Add comprehensive test coverage
- [ ] Implement automated testing pipeline
- [ ] Add performance testing
- [ ] Create security testing suite
- [ ] Implement continuous integration

---

## 🚀 **Future Refinements (Identified during Phases 1-3 Implementation)**

This section outlines areas for further enhancement and polish based on the current implementation.

### **Workflow Engine & Review Process**
- **Dynamic Workflow Logic**: The `RegulationReview#load_workflow_spec` currently simplifies decision step transitions (all options trigger 'approve'). Future refinement could allow defining specific target states for each decision option within the `WorkflowStep` configuration.
- **Workflow Step Types**: Explore additional `step_type` options beyond 'review', 'decision', 'classification', and 'acknowledgement' to support more complex workflows.

### **AI-Assisted Features**
- **Requirement Suggestion Service**:
    - Improve prompt engineering for `RequirementSuggestionService` to generate more precise and comprehensive requirements.
    - Enhance error handling for LLM failures (e.g., invalid JSON response, API errors).
    - Allow administrators to customize the LLM prompt for requirement generation.
    - Implement a mechanism to provide feedback on AI-generated suggestions to refine future outputs.
- **AI Model Fine-tuning**: Develop a process to use collected feedback (e.g., on AI-generated requirements) to fine-tune the underlying LLM models for improved accuracy and relevance.

### **User Interface & Experience (UI/UX)**
- **General Polish**: Enhance the overall visual design and user experience across all new features (workflow, task management, dashboard).
- **Loading States & Feedback**: Implement more explicit loading states and user feedback mechanisms for asynchronous operations (e.g., AI suggestions, task updates).
- **Interactive Elements**: Explore more interactive elements and visualizations for data presentation (e.g., advanced charting options, drag-and-drop for workflow step reordering).

### **Error Handling & Robustness**
- **Comprehensive Error Reporting**: Improve error reporting and user-facing messages for all new features, especially for form submissions and API interactions.
- **Validation Feedback**: Enhance client-side and server-side validation feedback for forms.

### **Authorization & Security**
- **Pundit Policies**: Develop comprehensive Pundit policies for all new models and actions (e.g., `RegulationReview`, `WorkflowTemplate`, `WorkflowStep`, `ComplianceControl` assignment, `Task` management) to ensure granular access control.

### **Reporting & Analytics**
- **Advanced Dashboard Views**: Expand the compliance dashboard with more detailed reports, filtering options (by framework, user, date range), and user-specific views.
- **Customizable Reports**: Allow users to create and save custom reports based on various compliance data points.

### **Active Tables Enhancements**
- **Editable Cells**: Allow users to manually edit cells in the Active Tables view (except for the Regulation title) after AI extraction. This enables users to refine or add information before exporting.
- **Real-time Extraction Status**: Implement status tracking (Queued, Processing, Completed) for AI extractions with real-time UI updates via Turbo Streams.

---

## 🤖 **next: AI Improvement Sprint**

All 23 AI-driven features need consolidation and upgrading. See `project_status/ai_improvement_sprint.md` for the full analysis.

**Key priorities:**
- [ ] Create shared `Ai::Client` wrapper (centralized logging, token tracking, retries)
- [ ] Create `Ai::ResponseParser` (replace 10+ duplicate JSON extraction patterns)
- [ ] Activate `ModelRouter` across all services (currently dead code)
- [ ] Wire `AgentTrace` recording into all AI calls
- [ ] Upgrade 6 keyword-matching services to use `RubyLLM`
- [ ] Deduplicate `RegulationProcessorService` vs `RegulationSupervisor`

## ⚖️ **Legal & Compliance Enhancements (Roadmap)**

### **1. The "Golden Thread" of Traceability**
- [ ] **Policy Management Module**: Create `Policy` model with linking to `Regulation` citations.
- [ ] **Gap Analysis**: Visual view showing Regulations with no linked Policies.
- [ ] **Evidence Request Workflow**: Secure upload portal for non-users (auditors/contractors).

### **2. Collaboration & "Redlining"**
- [ ] **Granular Commenting**: Comment on specific lines of Regulation/Policy text.
- [ ] **Visual Redlining (Diff View)**: Side-by-side redline of Regulation changes (Old vs. New).
- [ ] **Approval Chains**: Multi-stage approvals (Draft -> Legal -> CISO -> Board).

### **3. Audit & Assurance**
- [ ] **Immutable Audit Logs**: User-facing audit trail for every object.
- [ ] **Snapshotting**: Point-in-time compliance snapshots for audits.

### **4. Intelligence & Reporting**
- [ ] **Board-Ready Reports**: One-click executive summary PDF generation.
- [ ] **Regulatory Horizon Scanning**: AI-driven impact assessment for new regulations.

---

*Last Updated: 2026-02-18*
*Status: Phases 1-5 Complete. AI Improvement Sprint planned next.*