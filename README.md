<p align="center">
  <h1 align="center">🏛️ ComplyFlow</h1>
  <p align="center"><strong>The AI-Native Compliance Operating System</strong></p>
  <p align="center">
    Automated regulatory intelligence · Multi-tenant GRC · AI-powered workflows
  </p>
</p>

---

## What Is ComplyFlow?

ComplyFlow is a **compliance management platform** that helps companies stay on top of ever-changing laws and regulations — automatically.

Think of it like a smart assistant for your legal and compliance teams: it watches for new rules from government agencies, reads and summarizes them using AI, tells the right people in your company what they need to do, and tracks everything until it's done.

### The Problem It Solves

Every company operating in regulated industries (finance, healthcare, insurance, etc.) must follow hundreds of rules from dozens of government agencies. Those rules change **constantly**. Today, most companies track this in spreadsheets, email chains, and manual processes — it's slow, error-prone, and expensive.

### How ComplyFlow Fixes It

```mermaid
graph LR
    A["1️⃣ DISCOVER<br/>Automatically finds<br/>new regulations"] --> B["2️⃣ UNDERSTAND<br/>AI reads & summarizes<br/>what's required"]
    B --> C["3️⃣ ASSIGN<br/>Routes tasks to<br/>the right teams"]
    C --> D["4️⃣ REVIEW<br/>Teams approve via<br/>built-in workflows"]
    D --> E["5️⃣ IMPLEMENT<br/>Break into tasks<br/>with deadlines"]
    E --> F["6️⃣ PROVE<br/>Collect evidence &<br/>sign-off on compliance"]
    F --> G["7️⃣ MONITOR<br/>Dashboards show<br/>real-time status"]
    G --> A

    style A fill:#1a73e8,color:#fff
    style B fill:#7c3aed,color:#fff
    style C fill:#059669,color:#fff
    style D fill:#d97706,color:#fff
    style E fill:#dc2626,color:#fff
    style F fill:#2563eb,color:#fff
    style G fill:#0891b2,color:#fff
```

| Without ComplyFlow | With ComplyFlow |
|---|---|
| Regulations change weekly — teams find out too late | **Automatic monitoring** of 10+ government sources |
| Staff manually read 100-page legal documents | **AI summarizes obligations** in seconds |
| "Who handles this?" is a daily question | **Auto-routes** to the right department |
| Compliance tracked in scattered spreadsheets | **One dashboard** across all frameworks |
| Auditors ask for proof and teams scramble | **Evidence trail** is always up to date |

### Real-World Example: A FinTech Onboards

| Timeline | What Happens |
|---|---|
| **Day 1** | Admin sets up the company, selects industry (FinTech) and locations (US, NY, CA) |
| **Day 1** | ComplyFlow auto-matches 40+ relevant regulations (SEC, CFPB, CCPA, NYDFS) |
| **Day 2** | Review workflows begin — Legal gets SEC rules, Privacy team gets data protection rules |
| **Week 1** | Teams approve applicable rules; AI breaks them into 200+ actionable requirements |
| **Week 2** | Requirements become trackable tasks on Kanban boards with owners and due dates |
| **Ongoing** | Evidence is collected, dashboards update in real-time |
| **Audit Day** | One-click report generation with a complete, tamper-proof evidence trail |

### Key Capabilities at a Glance

| Capability | What It Does |
|---|---|
| 🌐 **Regulatory Monitoring** | Continuously watches government agencies for new and changed rules |
| 🤖 **AI Analysis** | Reads legal text and extracts who needs to do what, by when |
| 📋 **Workflow Automation** | Routes reviews and approvals through configurable multi-step processes |
| 📊 **Compliance Dashboards** | Real-time visibility across all frameworks (SOC 2, HIPAA, ISO 27001, etc.) |
| ⚖️ **Risk Management** | Visual risk heatmaps with control linkage |
| 🔍 **Control Testing** | Scheduled test plans, statistical sampling, and audit-ready sign-offs |
| 📄 **Policy Attestation** | Campaign-based policy acknowledgments with tamper-proof legal records |
| 🏢 **Multi-Tenant** | Supports many organizations on one platform, each fully isolated |
| 🚩 **Feature Flags** | Modules can be turned on/off per customer |
| 🔗 **API Access** | Programmatic access for integrations with other tools |

---

## Built With

> Ruby on Rails · PostgreSQL · Python · Google Gemini AI · Hotwire · Redis · Docker

---

<details>
<summary><h2>🔧 Technical Deep Dive (click to expand)</h2></summary>

### Platform Architecture

```mermaid
graph TB
    subgraph External["🌐 External Sources"]
        GOV["Government APIs<br/>(SEC, OCC, regulations.gov)"]
        RSS["RSS Feeds"]
        WEB["Regulatory Websites"]
    end

    subgraph Scraper["🐍 Python Scraper Microservice"]
        FAST["FastAPI Server"]
        SCRAP["Scrapling Engine<br/>(Anti-bot bypass)"]
        LITELLM["LiteLLM<br/>(AI Navigation)"]
    end

    subgraph Rails["🛤️ Rails Core Platform"]
        INGEST["Ingestion Engine<br/>(RegulatoryScraperService)"]
        PROC["AI Processor<br/>(RegulationProcessorService)"]
        AUTO["Auto-Assignment<br/>(RegulationAutoAssignmentService)"]
        WORKFLOW["Workflow Engine<br/>(WorkflowTemplate + Steps)"]
        TASK["Task Management<br/>(Kanban / Assignments)"]
        INTEL["Intelligence Layer<br/>(11 AI Modules)"]
    end

    subgraph Data["💾 Data Layer"]
        PG["PostgreSQL<br/>+ pgvector"]
        REDIS["Redis<br/>(Cache + Jobs)"]
        AS["Active Storage<br/>(Documents)"]
    end

    subgraph Users["👥 Tenant Users"]
        ADMIN["Org Admins"]
        COMP["Compliance Managers"]
        STAKE["Stakeholders"]
        AUD["Auditors"]
    end

    GOV --> INGEST
    RSS --> INGEST
    WEB --> FAST
    FAST --> SCRAP
    SCRAP --> LITELLM
    FAST -- "Webhook POST" --> INGEST
    INGEST --> PROC
    PROC --> AUTO
    AUTO --> WORKFLOW
    WORKFLOW --> TASK
    TASK --> INTEL

    Rails --> PG
    Rails --> REDIS
    Rails --> AS

    ADMIN --> Rails
    COMP --> Rails
    STAKE --> Rails
    AUD --> Rails
```

### Request & Data Flow

```mermaid
sequenceDiagram
    participant SRC as 🌐 Regulatory Source
    participant SCR as 🐍 Scraper Service
    participant ING as ⚙️ Ingestion Engine
    participant AI as 🤖 AI Processor
    participant DB as 💾 PostgreSQL
    participant AA as 🎯 Auto-Assignment
    participant WF as 📋 Workflow Engine
    participant USR as 👤 Stakeholder

    SRC->>ING: New regulation detected (API/RSS)
    SRC->>SCR: Complex site requires scraping
    SCR->>SCR: AI navigates site, bypasses bot protection
    SCR->>ING: POST /webhooks/scraper (extracted text)
    ING->>DB: Save raw Regulation record
    ING->>AI: ProcessRegulationJob (async)
    AI->>AI: Extract jurisdiction, agency, summary
    AI->>AI: Segment into Obligations
    AI->>AI: Classify by entity type, topic, risk
    AI->>DB: Update Regulation + create Requirements
    AI->>AA: Trigger auto-assignment
    AA->>AA: Match org profile (industry + jurisdiction)
    AA->>DB: Create OrganizationRegulation links
    AA->>WF: Create RegulationReview from template
    WF->>USR: 📧 Notification: "New review assigned"
    USR->>WF: Review, comment, approve/reject
    WF->>WF: Advance to next step/role
    WF->>DB: Log decisions + create implementation tasks
```

---

### Core Module Architecture

```mermaid
graph TB
    subgraph Core["🏗️ Core Platform"]
        MT["Multi-Tenancy<br/>(Organizations, Depts, Teams)"]
        UAC["User & Access Control<br/>(Devise, Pundit, Rolify)"]
        DOC["Document Management<br/>(Upload, Preview, Version)"]
    end

    subgraph GRC["⚖️ GRC Modules"]
        CF["Compliance Frameworks<br/>(Requirements, Controls)"]
        RM["Risk Management<br/>(Register, Heatmap)"]
        FR["Findings & CAPA<br/>(Auto-create, SLA, Root Cause)"]
        CT["Control Testing<br/>(Plans, Sampling, Sign-off)"]
        OB["Obligation Management<br/>(AI Extraction, Triggers)"]
        IB["Incident & Breach<br/>(Categories, Auto-findings)"]
        PA["Policy Attestation<br/>(Campaigns, Legal Records)"]
        EF["Evidence Freshness<br/>(Expiration, Auto-refresh)"]
    end

    subgraph Intelligence["🧠 Phase 5 Intelligence"]
        MA["Maturity Assessment"]
        HM["Cross-Framework<br/>Harmonization"]
        WI["Workflow Intelligence"]
        PG["Policy Gap Analysis"]
        IS["Impact Simulation"]
        ER["Executive Reports"]
        QA["Questionnaire Autofill"]
        VR["Vendor TPRM"]
        EA["Evidence Agents"]
        CM["Continuous Monitoring"]
        EI["Jira/Linear/ServiceNow"]
    end

    Core --> GRC
    GRC --> Intelligence
```

### Module Details

| Module | Description | Key Capability |
|---|---|---|
| **Compliance Frameworks** | Define and manage frameworks (SOC 2, ISO 27001, HIPAA, etc.) | AI-assisted requirement breakdown from regulation text |
| **Risk Management** | Risk register with severity/likelihood scoring | Visual heatmap + control linkage |
| **Findings & CAPA** | Corrective and Preventive Actions | Auto-created from failed tests or incidents, SLA tracking |
| **Control Testing** | Scheduled test plans with sampling strategies | Statistical sampling, reviewer sign-off, trend analysis |
| **Obligation Management** | AI-extracted duties from legal text | Conditional triggers (e.g., GDPR 72-hour breach notification) |
| **Incident Management** | Log breaches with 9 categories, 4 severity levels | Auto-triggers related obligations, creates findings |
| **Policy Attestation** | Campaign-based policy acknowledgment | Immutable legal records (IP, user agent, timestamp) |
| **Evidence Freshness** | Track document expiration dates | Auto-refresh requests before evidence goes stale |
| **Active Tables** | Spreadsheet-like AI queries on regulation text | Ask "What are the penalties?" — AI fills the column |
| **Executive Reports** | AI-generated compliance narratives | Board-ready PDF exports with maturity scores |
| **Vendor TPRM** | Third-party risk assessments | Track vendor compliance posture |

---

### The Regulatory Ingestion Engine

#### Source Strategy: "Golden Sources First"

```mermaid
graph TB
    subgraph Tier1["Tier 1: Official APIs (Preferred)"]
        SEC["SEC EDGAR API"]
        REGSGOV["Regulations.gov API"]
        GOVINFO["GovInfo API (CFR/FR)"]
        LEGUK["legislation.gov.uk"]
        EURLEX["EUR-Lex Web Services"]
    end

    subgraph Tier2["Tier 2: Structured Feeds"]
        RSS1["SEC RSS Feeds"]
        RSS2["OCC Bulletins RSS"]
        RSS3["State Agency Feeds"]
    end

    subgraph Tier3["Tier 3: AI Web Scraping"]
        PY["Python Scrapling Engine"]
        PY --> |"Anti-bot<br/>bypass"| ANTI["Complex Gov Sites"]
        PY --> |"LiteLLM<br/>navigation"| DEEP["Deep Link Discovery"]
    end

    Tier1 --> NORM["Normalization Layer"]
    Tier2 --> NORM
    Tier3 --> NORM
    NORM --> AI_P["AI Processing Pipeline"]
    AI_P --> DB_R["Regulation Database<br/>(pgvector embeddings)"]
```

#### Configurable Data Sources

Each `RegulatoryDataSource` record defines:

| Field | Purpose | Example |
|---|---|---|
| `source_type` | Ingestion strategy | `api`, `rss`, `web_scrape`, `external_scrapling` |
| `url` | Endpoint or page to monitor | `https://efts.sec.gov/LATEST/search-index?...` |
| `api_field_mapping` | Maps response JSON to internal fields | `{ results: "hits", title: "name", url: "url" }` |
| `pagination_strategy` | How to page through results | `page_number`, `offset`, or `none` |
| `active` | Enable/disable without deleting | `true` / `false` |

---

### AI Intelligence Layer

```mermaid
graph LR
    subgraph Core_AI["Core AI Infrastructure"]
        CLIENT["Ai::Client<br/>(Centralized wrapper)"]
        ROUTER["Ai::ModelRouter<br/>(Model selection)"]
        PARSER["Ai::ResponseParser<br/>(JSON extraction)"]
        EMBED["Ai::EmbeddingService<br/>(pgvector search)"]
    end

    subgraph Regulation_AI["Regulation Intelligence"]
        RPROC["RegulationProcessorService<br/>(Metadata extraction)"]
        RSUP["RegulationSupervisor<br/>(Segmentation)"]
        REXT["RegulationExtractionService<br/>(Active Tables)"]
        RDIFF["RegulationDiffService<br/>(Change tracking)"]
    end

    subgraph Compliance_AI["Compliance Intelligence"]
        MSCORE["MaturityScoringService"]
        HARM["HarmonizationService"]
        PGAP["PolicyGapAnalysisService"]
        IMPACT["ImpactPredictionService"]
        EXEC["ExecutiveReportService"]
        QUEST["QuestionnaireAutofillService"]
    end

    subgraph Agent_AI["AI Agents"]
        DISC["DiscoverySupervisor"]
        FILTER["FilterAgent"]
        IMPACT_A["ImpactAnalysisAgent"]
        ORCH["OrchestratorAgent"]
        RESEARCH["OrganizationResearchAgent"]
    end

    CLIENT --> Regulation_AI
    CLIENT --> Compliance_AI
    CLIENT --> Agent_AI
    ROUTER --> CLIENT
    PARSER --> CLIENT
```

**AI Model:** Google Gemini (`gemini-2.0-flash` for generation, `text-embedding-004` for vector search)

---

### Multi-Tenancy & Access Control

```mermaid
graph TB
    subgraph Tenant["Organization (Tenant Boundary)"]
        ORG["🏢 Organization<br/>(Branding, Profile, Settings)"]
        ORG --> DEPT1["Department A"]
        ORG --> DEPT2["Department B"]
        DEPT1 --> TEAM1["Team 1"]
        DEPT1 --> TEAM2["Team 2"]
        TEAM1 --> UNIT1["Unit 1"]
        DEPT2 --> TEAM3["Team 3"]
    end

    subgraph Access["Access Control Stack"]
        DEV["Devise<br/>(Authentication)"]
        ROL["Rolify<br/>(Role Assignment)"]
        PUN["Pundit<br/>(Policy Enforcement)"]
        PERM["Permission Model<br/>(Granular CRUD)"]
        FLIP["Flipper<br/>(Feature Gating)"]
    end

    Tenant --> Access
```

- **`acts_as_tenant`** ensures every database query is scoped to the current organization
- **Rolify** defines roles (Super Admin, Org Admin, Compliance Manager, Stakeholder, Auditor)
- **Pundit policies** enforce row-level access checks on every controller action
- **Flipper flags** gate entire modules on/off per tenant (23 flags across all modules)

---

### Feature Flag System

All modules are gated behind **Flipper feature flags**, allowing per-tenant feature activation:

| Flag | Module | Phase |
|---|---|---|
| `compliance_management` | Frameworks, Requirements, Controls | Core |
| `risk_management` | Risk Register, Heatmap | Core |
| `document_management` | Document Library | Core |
| `policies` | Policy Management | Core |
| `regulatory_intelligence` | Regulation Library | Core |
| `findings_remediation` | Findings & CAPA | Phase 2 |
| `control_testing` | Test Plans & Execution | Phase 3 |
| `obligation_management` | Obligation Tracking | Phase 4 |
| `incident_management` | Incident & Breach | Phase 4 |
| `policy_attestation` | Attestation Campaigns | Phase 3 |
| `evidence_freshness` | Evidence Expiration | Core |
| `maturity_assessment` | Control Maturity Scoring | Phase 5A |
| `cross_framework_harmonization` | Framework Mapping | Phase 5A |
| `workflow_intelligence` | Workflow Analytics | Phase 5A |
| `policy_gap_analysis` | Policy Gap Detection | Phase 5A |
| `regulatory_impact_simulation` | Impact Simulation | Phase 5B |
| `executive_reporting` | Executive Reports | Phase 5B |
| `questionnaire_autofill` | Questionnaire/RFP Autofill | Phase 5B |
| `vendor_risk_management` | Vendor TPRM | Phase 5C |
| `evidence_agents` | Automated Evidence Collection | Phase 5C |
| `continuous_monitoring` | Monitoring Dashboard | Phase 5C |
| `external_integrations` | Jira/Linear/ServiceNow | Phase 5D |
| `compliance_exports` | CSV/PDF Exports | Core |

---

### Full Tech Stack

| Layer | Technology |
|---|---|
| **Backend** | Ruby on Rails 7.1 |
| **Scraper Microservice** | Python 3.12, FastAPI, Scrapling, LiteLLM |
| **Database** | PostgreSQL 15+ with `pgvector` extension |
| **Cache & Jobs** | Redis + Sidekiq |
| **Frontend** | Hotwire (Turbo + Stimulus), Tailwind CSS, ViewComponent |
| **Authentication** | Devise |
| **Authorization** | Pundit + Rolify |
| **Multi-Tenancy** | `acts_as_tenant` |
| **AI Models** | Google Gemini (via `ruby_llm` gem) |
| **Vector Search** | `neighbor` gem + pgvector |
| **Feature Flags** | Flipper |
| **File Storage** | Active Storage |
| **Document Processing** | LibreOffice, Poppler, Tesseract OCR, ImageMagick |
| **Testing** | RSpec, FactoryBot, Capybara |
| **Containerization** | Docker |

---

### Getting Started

#### Prerequisites

- Ruby 3.2+
- PostgreSQL 15+ (with `pgvector` extension enabled)
- Redis
- Node.js 18+ (for asset compilation)
- Python 3.12+ (for scraper microservice)

#### System Dependencies

```bash
# Ubuntu/Debian
sudo apt-get install -y poppler-utils tesseract-ocr tesseract-ocr-eng \
  libreoffice ghostscript imagemagick

# macOS
brew install poppler tesseract tesseract-lang libreoffice ghostscript imagemagick
```

#### Installation

```bash
# 1. Clone and install Ruby dependencies
git clone <repository-url>
cd compliance_tracker
bundle install

# 2. Set up the database
rails db:create db:migrate db:seed

# 3. Start Redis and Sidekiq (for background jobs)
redis-server &
bundle exec sidekiq &

# 4. Start the Rails server
bin/dev   # or: rails server
```

#### Running the Scraper Microservice

```bash
cd scraper_service
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --port 8000 --reload
```

The scraper service exposes a FastAPI endpoint on port `8000` that the `RegulatoryScraperService` dispatches to for complex web scraping tasks.

#### Access the Platform

Visit `http://localhost:3000` — log in with seed credentials and start exploring.

---

### API

ComplyFlow exposes a versioned RESTful API at `/api/v1` for programmatic access:

- **Compliance data** — Frameworks, requirements, controls
- **Documents** — Upload, retrieve, search
- **Regulations** — Browse, filter, adopt
- **Organization management** — Users, roles, departments

API authentication is handled via Devise token authentication.

</details>

---

## License

This project is licensed under the MIT License.

---

<p align="center">
  <strong>ComplyFlow</strong> — Because compliance shouldn't be a full-time job.<br/>
  <em>Built by humans, powered by AI, trusted by auditors.</em>
</p>
