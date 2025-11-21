# Gemini Project Context: Compliance Tracker

This document summarizes the key aspects of the Compliance Tracker project to provide context for development sessions.

### Project Overview
The project is a comprehensive, multi-tenant compliance management platform built with Ruby on Rails. It enables organizations to manage their compliance frameworks, requirements, controls, and documents. A major upcoming feature is a sophisticated "Regulatory Change Management Workflow" designed to automate the ingestion, analysis, and implementation of regulatory changes.

### Core Features
*   **Multi-Tenancy:** Supports isolated organizations, each with its own hierarchy of departments, teams, and units.
*   **User & Access Control:** A robust permission system using Devise, Pundit, and Rolify for authentication, authorization, and role-based access control (RBAC). Permissions are granular and scoped to organizations.
*   **Compliance Management:** Allows creation and management of compliance frameworks, requirements, and controls.
*   **Document Management:** Features document uploads, versioning, approval workflows, and previews for various file types (PDF, Office, images).
*   **Risk Assessment:** Functionality for assessing and tracking risks related to compliance controls.
*   **Provider Management:** A system for managing regulatory bodies or other providers, both globally and per-organization.
*   **Regulatory Change Workflow (Roadmap):** The next major feature set, which includes:
    *   Automated ingestion and AI-tagging of new regulations.
    *   A structured review and decision workflow for stakeholders.
    *   Task management for implementing regulatory changes.
    *   Dashboards and reporting for tracking progress.

### Technical Stack
*   **Backend:** Ruby on Rails 7.1
*   **Database:** PostgreSQL (with `pgvector` for AI features)
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
    *   `web_scrape`: Can use either a specific CSS selector or an LLM for more robust link extraction, configured via the data source's `settings`.
    *   `rss`: Parses RSS feeds to find new regulation links.
    *   `api`: A placeholder for future implementation of direct API ingestion.
*   **Admin Interface**: A new CRUD interface at `/admin/regulatory_data_sources` allows administrators to manage these configurations. It is accessible via a new "Admin" dropdown in the main navigation, which is only visible to super admins.

### AI Enrichment (formerly "Cube Tagging")
*   **Terminology Clarification**: The term "Cube Tagging" was identified as a reference to a competitor's feature. The actual goal is to implement a rich metadata enrichment process for ingested regulations.
*   **Implementation**:
    *   The `RegulationProcessorService` is triggered by the `ProcessRegulationJob` after a regulation is scraped.
    *   It uses an LLM to analyze the regulation's text and extract key metadata: `jurisdiction`, `agency`, `effective_date`, `summary`, `keywords`, `compliance_requirements_overview`, `potential_impacted_industries`, and `risk_level`.
    *   This data is used to populate both the top-level columns and the `metadata` JSONB field of the `Regulation` model.
*   **Feature Set**: Based on this enriched data, the following features have been implemented:
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

### Development Roadmap
The immediate focus is on building the **Regulatory Change Management Workflow**, as detailed in `TODO.md`:
*   **Phase 1: Automated Ingestion and AI-powered processing of regulations. (COMPLETED)**
*   **Phase 2: Stakeholder Review and Decision Workflow. (COMPLETED)**
*   **Phase 3: Implementation, Task Management, and Reporting. (COMPLETED)**
*   **Phase 4:** Advanced Analytics and Integrations.

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



### **Advanced Regulatory Data Ingestion by Sector**



This plan outlines a future refinement to the regulatory data ingestion process, moving from a source-specific approach to a more comprehensive, sector-based approach.



**Phase 1: Discovery and Curation of Data Sources**



1.  **Automated Source Discovery:**

    *   Develop a "Source Discovery Agent" that uses web search and LLMs to find relevant regulatory bodies, government agencies, and other sources of regulatory information for a given sector and jurisdiction.

    *   The agent would take a sector (e.g., "Healthcare", "Finance") and a jurisdiction (e.g., "USA", "EU") as input and return a list of potential data sources (websites, RSS feeds, API endpoints).

    *   The agent would also attempt to identify the type of each source (e.g., `web_scrape`, `rss`, `api`).



2.  **Source Curation and Management:**

    *   Enhance the `RegulatoryDataSource` model to store more metadata about each source, such as the sectors and jurisdictions it covers.

    *   Build a UI for administrators to review, approve, and curate the discovered data sources.

    *   The UI would allow administrators to manually add, edit, and tag data sources with relevant sectors and jurisdictions.



**Phase 2: Intelligent and Adaptive Data Ingestion**



1.  **Generic Scraper with Adaptive Parsing:**

    *   Refactor the `RegulatoryScraperService` to be more generic and adaptive.

    *   Instead of relying on a specific CSS selector, the scraper would use an LLM to analyze the structure of a webpage and identify the relevant content to extract (e.g., the main body of a regulation, its title, publication date, etc.).

    *   The scraper would be able to handle a wider variety of website layouts and structures without needing to be reconfigured for each source.



2.  **Multi-Modal Data Ingestion:**

    *   Extend the scraper to handle different types of content, including PDFs, Word documents, and other common formats.

    *   Integrate with document processing libraries and services to extract text and metadata from these files.

    *   For sources that provide APIs, develop a flexible API client that can be configured to work with different API specifications.



**Phase 3: AI-Powered Processing and Enrichment**



1.  **Sector and Topic Classification:**

    *   Enhance the `RegulationProcessorService` to use an LLM to automatically classify each ingested regulation by sector, topic, and sub-topic.

    *   The service would analyze the full text of the regulation and assign it to one or more predefined categories (e.g., "Healthcare > Medical Devices > FDA Regulations").

    *   This would allow users to browse and search for regulations by sector and topic, without needing to know the specific source.



2.  **Extraction of Key Information:**

    *   Use an LLM to extract key information from each regulation, such as:

        *   **Applicability:** Who the regulation applies to (e.g., specific industries, company sizes, etc.).

        *   **Requirements:** The specific actions that need to be taken to comply with the regulation.

        *   **Deadlines:** Any deadlines for compliance.

        *   **Penalties:** The penalties for non-compliance.

    *   This extracted information would be stored in a structured format in the database, making it easy to search and analyze.



**Phase 4: Scalability, Monitoring, and Continuous Improvement**



1.  **Scalable Architecture:**

    *   Design the ingestion pipeline to be scalable and resilient.

    *   Use a distributed task queue (like Sidekiq) to process the ingestion and processing jobs in parallel.

    *   Implement robust error handling and retry mechanisms to handle failures gracefully.



2.  **Monitoring and Alerting:**

    *   Build a dashboard to monitor the health and performance of the ingestion pipeline.

    *   The dashboard would show the status of each data source, the number of regulations being ingested, and any errors that have occurred.

    *   Set up alerts to notify administrators of any failures or anomalies in the pipeline.



3.  **Human-in-the-Loop Feedback:**

    *   Build a UI for users to provide feedback on the accuracy of the AI-powered classification and information extraction.

    *   This feedback would be used to fine-tune the LLM models and improve the accuracy of the system over time.
