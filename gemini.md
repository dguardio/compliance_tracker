# Gemini Project Context: Compliance Tracker

This document summarizes the key aspects of the Compliance Tracker project to provide context for development sessions.

### Project Overview
The project is a comprehensive, multi-tenant compliance management platform built with Ruby on Rails. It enables organizations to manage their compliance frameworks, requirements, controls, documents, risks, findings, incidents, obligations, attestations, vendors, and more. The platform features 23 Flipper-gated modules spanning 5 implementation phases, all complete. A sophisticated AI layer powers regulatory intelligence, policy generation, executive reporting, and impact analysis.

### Core Features
*   **Multi-Tenancy:** Supports isolated organizations, each with its own hierarchy of departments, teams, and units.
*   **User & Access Control:** A robust permission system using Devise, Pundit, and Rolify for authentication, authorization, and role-based access control (RBAC). Permissions are granular and scoped to organizations.
*   **Compliance Management:** Allows creation and management of compliance frameworks, requirements, and controls.
*   **Document & Policy Management:** Features document uploads, versioning, approval workflows, policy attestation, and previews.
*   **Risk Assessment:** Risk register, heatmap, and linking risks to controls.
*   **Findings & Remediation (CAPA):** Auto-creation of findings, SLA tracking, corrective actions, root cause analysis.
*   **Control Testing & Assurance:** Test plans, sample-based execution, sign-off workflows, historical trends.
*   **Obligation Management:** AI-extracted obligations from regulations, conditional triggers (e.g., GDPR 72h).
*   **Incident & Breach Management:** Incident logging, obligation triggering, auto-finding creation, lessons learned.
*   **Provider Management:** A system for managing regulatory bodies or other providers.
*   **Phase 5 — Intelligence & Advanced Features (11 modules):**
    *   Control Maturity Assessment & Cross-Framework Harmonization
    *   Workflow Intelligence & Policy Gap Analysis
    *   Regulatory Impact Simulation & Executive Reporting
    *   Questionnaire Autofill / RFP Responder
    *   Vendor TPRM & Automated Evidence Agents
    *   Continuous Monitoring Dashboard & Jira/Linear/ServiceNow Integration

### Technical Stack
*   **Backend:** Ruby on Rails 7.1 (Core Platform), FastAPI / Python 3.12 (Scraping Microservice)
*   **Database:** PostgreSQL (with `pgvector` for AI features), SQLite (Scraper job queue)
*   **Frontend:** Hotwire (Turbo, Stimulus), Tailwind CSS, ViewComponent
*   **Authentication/Authorization:** Devise, Pundit, Rolify
*   **Multi-tenancy:** `acts_as_tenant` gem
*   **Background Jobs:** Sidekiq
*   **AI & Scraping:** `langchainrb`, `ruby-openai`, `nokogiri`, `httparty`
*   **File Handling:** Active Storage, various gems for document processing (`docx`, `roo`, `pdf-reader`)
*   **Testing:** RSpec, FactoryBot, Capybara

### Data Models & Schema
*   **Tenancy:** `organizations`, `departments`, `teams`, `units` form the hierarchical structure.
*   **Users & Access:** `users`, `roles`, `permissions`, `memberships` manage access control. `acts_as_tenant` uses `organization` as the tenant.
*   **Hierarchical Data Model:** Data is structured hierarchically: Organization -> Department -> Team -> Unit.
*   **Policy-Based Authorization:** Pundit policies (`app/policies`) control access to resources based on user roles and permissions.
*   **Role-Based Access Control (RBAC):** The `rolify` gem is used to define roles which are then assigned permissions.
*   **RESTful API:** A versioned API is exposed under `/api/v1` for programmatic access to compliance data.
*   **Routing:** Routes in `config/routes.rb` are heavily nested. A new `/admin` namespace has been added for managing `Regulations` and `RegulatoryDataSources`.

### Ingestion Engine
*   **`RegulatoryScraperService`**: This service has been refactored to be driven by the `RegulatoryDataSource` model.
*   **Configurable Sources**: The engine iterates through enabled data sources, allowing for flexible and configurable ingestion.
*   **Multiple Strategies**: It supports different `source_type`s, including:
    *   `web_scrape`: Can use either a specific CSS selector, an LLM for robust link extraction locally, or **Dispatch to the External Python Scrapling Microservice**.
    *   `external_scrapling`: **Implemented.** An advanced LLM-powered Python crawler (`scrapling` + `litellm`) that bypasses anti-bot protections, autonomously navigates deep link structures via AI, and posts JSON data back to a Rails webhook endpoint asynchronously.
    *   `rss`: Parses RSS feeds to find new regulation links.
    *   `api`: Supports generic JSON API ingestion with configurable field mapping and pagination via `RegulatoryDataSource` settings.
*   **Admin Interface**: A new CRUD interface at `/admin/regulatory_data_sources` allows administrators to manage these configurations. It is accessible via a new "Admin" dropdown in the main navigation, which is only visible to super admins.

### AI Enrichment (formerly "Cube Tagging")
*   **Terminology Clarification**: The term "Cube Tagging" was identified as a reference to a competitor's feature. The actual goal is to implement a rich metadata enrichment process for ingested regulations.
*   **Implementation**:
    *   The `RegulationProcessorService` is triggered by the `ProcessRegulationJob` after a regulation is scraped.
    *   It uses an LLM to analyze the regulation's text and extract key metadata: `jurisdiction`, `agency`, `effective_date`, `summary`, `keywords`, `compliance_requirements_overview`, `potential_impacted_industries`, and `risk_level`.
    *   This data is used to populate both the top-level columns and the `metadata` JSONB field of the `Regulation` model.
    *   **Segmentation & Classification**: The `RegulationProcessorService` now uses an LLM to segment full text into individual "Obligations" (Requirements) and classifies them by "Entity Type", "Topic", and "Risk Level".
    *   **Data Drift**: The system now tracks `content_hash`, `effective_date`, and `agency` to detect changes and automatically create new `revision`s of regulations.
    1.  **Display**: The regulation `show` page in the admin section now displays the formatted AI-generated metadata.
    2.  **Search/Filter**: The admin `index` page for regulations now includes a comprehensive search and filter interface, allowing users to query by title, agency, jurisdiction, and keywords.
    3.  **Automation**: The `RegulationAutoAssignmentService` uses the `potential_impacted_industries` and `jurisdiction` metadata to automatically link new regulations to relevant organizations. Bugs in this existing service and its configuration have been fixed to make it operational.

### Dynamic Workflow Engine
*   **Core Concept**: A flexible workflow system has been built to allow each organization to define its own process for reviewing and actioning new regulations.
*   **Data Models**:
    *   `WorkflowTemplate`: A blueprint for a workflow, belonging to an organization.
    *   `WorkflowStep`: An individual, ordered step within a template, assignable to a user role. Steps can be of different types (`review`, `decision`, `classification`).
    *   `RegulationReview`: The state machine for a specific regulation's review process, powered by the `workflow` gem.
    *   `RegulationReviewDecision`: Logs the specific decision made at a `decision` step.
*   **Functionality**:
    *   **Admin UI**: Organization admins can create/manage `WorkflowTemplate`s and define their steps, including custom `decision_options` for decision steps.
    *   **Automation**: When a regulation is assigned to an organization, a `RegulationReview` is automatically created from the default template, kicking off the workflow.
    *   **Stakeholder UI**: A "My Reviews" dashboard shows users their assigned reviews. The review page allows users to see regulation details, add notes, and advance the workflow using buttons that are dynamically generated based on the current step's type and configuration.
    *   **Notifications**: Users are notified via the UI and email when a review is assigned to their role.

### Implementation, Task Management, and Reporting
*   **Regulation Breakdown**: A tool has been implemented on the Compliance Framework show page to allow compliance managers to break down a regulation into specific requirements. This includes an AI-assisted suggestion feature for generating requirements from regulation text.
*   **Task Assignment**: Compliance controls can now be assigned to individual users with a due date. Notifications are sent to assignees.
*   **Task Management UI**: A "My Tasks" Kanban board provides a drag-and-drop interface for users to manage their assigned compliance controls and update their status.
*   **Reporting & Dashboards**: The main dashboard has been enhanced with a new section for "Regulatory Task Implementation," displaying key metrics (total tasks, overdue, due soon) and a pie chart of tasks by status. A table of overdue tasks is also included.

### Active Tables & Organization Regulation Management
*   **Active Tables**: A dynamic tabular interface (`/admin/compliance_tables`) that allows users to analyze regulations using AI-extracted custom columns.
    *   **Custom Columns**: Users can define columns with natural language prompts (e.g., "What are the penalties?"), and the system uses an LLM to extract the data from the regulation text.
    *   **Inline Creation**: Custom columns can be created directly within the Active Tables view via a modal.
*   **Organization Regulation Management**: A system for organizations to manage their own library of regulations (`/admin/organization_regulations`).
    *   **Library Management**: Organizations can add/remove regulations from their library.
    *   **Auto-Assignment**: Regulations are automatically assigned to organizations based on their compliance profile (jurisdiction, industry, etc.). These show as "System" added.
    *   **Filtering**: Active Tables automatically filters to show only the regulations in the organization's library.
    *   **Editable Cells (Planned)**: Future enhancement to allow users to manually edit extracted data cells before export.
    *   **Real-time Status (Planned)**: Future enhancement to show "Thinking", "Processing", etc., in cells during AI extraction.

### Development Roadmap
The immediate focus is on building the **Regulatory Change Management Workflow**, as detailed in `TODO.md`:
*   **Phase 1: Automated Ingestion and AI-powered processing of regulations. (COMPLETED)**
*   **Phase 2: Stakeholder Review and Decision Workflow. (COMPLETED)**
*   **Phase 3: Implementation, Task Management, and Reporting. (COMPLETED)**
*   **Phase 4:** Advanced Analytics and Integrations. **(COMPLETED)**
*   **Phase 5:** Intelligence & Advanced Features (11 modules across 4 sub-phases). **(COMPLETED 2026-02-18)**
    *   5A: Control Maturity, Harmonization, Workflow Intelligence, Policy Gap Analysis
    *   5B: Impact Simulation, Executive Reports, Questionnaire Autofill
    *   5C: Vendor TPRM, Evidence Agents, Monitoring Dashboard
    *   5D: Jira/Linear/ServiceNow Integration
*   **Next: AI Improvement Sprint** — Consolidate and upgrade all 23 AI features. See `project_status/ai_improvement_sprint.md`.

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
-   **Fixed Issues**:
    -   Resolved `this` context binding issues in `WorkflowEditorController` by using arrow functions.
    -   Fixed PDF export missing content by implementing server-side rendering (`HighlightedJsonRenderer`).
    -   Fixed `NoMethodError` in Regulation views by correcting route helpers.

### **Authorization & Security**

-   **Pundit Policies**: Comprehensive Pundit policies have been implemented for `Regulation`, `Policy`, and `Comment` models.
    -   **Dynamic Permissions**: `RegulationPolicy` and `PolicyPolicy` now use the dynamic `Permission` model (via `can?` checks) instead of hardcoded roles.
    -   **Multi-Tenancy**: `CommentPolicy` and `Admin::EvidenceController` have been secured to prevent cross-organization data leaks.
    -   **Future Work**: Continue developing policies for remaining new models as they are added.

### **Advanced Regulatory Data Ingestion Strategy**

This strategy moves beyond simple scraping to a "Golden Source" and "Intelligence Layer" approach, ensuring high-quality, resilient data ingestion.

#### **1. The "Golden Sources" (Official & Open APIs)**
We prioritize official government APIs over scraping HTML, as they provide structured, reliable data.
*   **United States**:
    *   **Regulations.gov API**: Primary source for federal regulations, dockets, and comments.
    *   **GovInfo API**: Source for the Federal Register and CFR in XML.
    *   **OpenStates.org**: Aggregator for state-level legislation (GraphQL).
*   **International**:
    *   **legislation.gov.uk**: UK legislation in Akoma Ntoso XML.
    *   **EUR-Lex**: EU law web services.
    *   **WorldLII/AustLII**: Aggregators for global jurisdictions (bulk discovery).

#### **2. The "Intelligence" Layer (AI/NLP)**
Ingestion is not just downloading text; it is about extracting structured "Obligations".
*   **Pipeline**:
    1.  **Ingest**: Fetch data from API or Scraper.
    2.  **Segment**: Break down full text into individual "Requirements" (Obligations) using AI.
    3.  **Classify**: Tag each requirement with:
        *   **Entity Type**: Who does this apply to?
        *   **Topic/Risk**: What is the domain?
        *   **Action**: What must be done (e.g., "Report", "Audit")?
*   **Data Drift**: We treat regulations as versioned code (Git for Law), tracking `effective_date` and changes over time to prevent "drift".

#### **3. Tech Stack & Architecture**
*   **Current (Ruby)**: We are building the "Golden Source" capability within the existing Ruby stack (`HTTParty`, `Nokogiri`, `RubyLLM`) to maintain architectural consistency.
*   **Future (Python)**: For complex, non-API sources, we may introduce **Juriscraper** (Python) and **Scrapy**.
*   **Standardization**: We aim to map data to **Akoma Ntoso** (LegalDocML) standards where possible for interoperability.

#### **4. Future Roadmap (Buy vs. Build)**
*   **Commercial Data**: As the platform scales, we will consider licensing "base layer" data from providers like **vLex** (Iceberg API) to ensure global coverage without managing hundreds of scrapers.
*   **Advanced NLP**: Fine-tuning **Legal-BERT** models for superior classification compared to generic LLMs.

