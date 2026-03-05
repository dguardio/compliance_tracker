# AI Improvement Sprint — Compliance Tracker

> **Goal**: Audit, consolidate, and upgrade all AI-driven features across the application.  
> **LLM Provider**: Google Gemini via `ruby_llm` gem  
> **Date Created**: 2026-02-18

---

## Configuration Baseline

```ruby
# config/initializers/ruby_llm.rb
RubyLLM.configure do |config|
  config.gemini_api_key = gemini_api_key
  config.default_model = 'gemini-2.0-flash'
  config.default_embedding_model = 'text-embedding-004'
end
```

Models in use:
- `gemini-2.0-flash` — default for most features
- `gemini-2.0-flash-lite` — used by `ModelRouter` for classification
- `gemini-1.5-pro` — used by `ImpactAnalysisAgent` for complex reasoning

---

## PART A: Existing RubyLLM Features (17)

### A1. Compliance Assistant
- **File**: `app/controllers/admin/compliance_assistant_controller.rb`
- **Pattern**: Controller-level LLM call (RAG-lite)
- **What it does**: Builds context from selected regulations, answers user questions
- **Issues**:
  - ❌ LLM call directly in controller — should be extracted to a service
  - ❌ No conversation history (stateless)
  - ❌ Arbitrary `truncate(500)` per regulation — no token counting
  - ❌ No streaming support
- **Improvements**:
  - [ ] Extract to `Ai::ComplianceAssistantService`
  - [ ] Add conversation memory (session-based or DB-backed)
  - [ ] Use `ModelRouter` for model selection
  - [ ] Add token-aware context windowing
  - [ ] Consider streaming responses via Turbo Streams

### A2. AI Search Service
- **File**: `app/services/ai_search_service.rb`
- **Pattern**: Static method — query expansion via LLM
- **What it does**: Generates 5-7 synonyms/keywords to expand search queries
- **Issues**:
  - ⚠️ No caching — same query hits LLM every time
  - ⚠️ Silent failure (returns `[]` on error)
- **Improvements**:
  - [ ] Add Rails cache with TTL (e.g., `Rails.cache.fetch("ai_search:#{term}", expires_in: 24.hours)`)
  - [ ] Move into `Ai::` namespace for consistency
  - [ ] Use `flash-lite` model (this is a simple task)

### A3. Organization Research Agent
- **File**: `app/services/ai/organization_research_agent.rb`
- **Pattern**: **Agentic** — most sophisticated feature; uses `with_tools` + `with_instructions`
- **What it does**: Multi-step web research to build org compliance profile using GoogleSearch + WebReader tools
- **Strengths**: ✅ Proper tool-use pattern. ✅ Real-time Turbo Stream broadcasting. ✅ Error state persistence
- **Issues**:
  - ⚠️ Hardcoded to `gemini-2.0-flash` — doesn't use `ModelRouter`
  - ⚠️ No `AgentTrace` recording (logs to Turbo Stream but doesn't persist)
  - ⚠️ JSON extraction via regex could fail on edge cases
- **Improvements**:
  - [ ] Write traces to `Ai::AgentTrace` model for observability
  - [ ] Use `ModelRouter` for model selection
  - [ ] Add structured output parsing utility (shared)

### A4. Regulatory Discovery Agent ("Watchdog")
- **File**: `app/services/ai/regulatory_discovery_agent.rb`
- **Pattern**: Autonomous loop agent — iterates topics → searches → filters → ingests
- **What it does**: Proactively scans for new regulations via Google Search + FilterAgent
- **Strengths**: ✅ Deduplication against DB. ✅ Max iteration safety (`MAX_ITERATIONS = 5`)
- **Issues**:
  - ⚠️ Hardcoded search topics (should be dynamic per org)
  - ⚠️ Creates `RegulatoryDataSource` records ad-hoc — could orphan data
  - ⚠️ No scheduling mechanism
- **Improvements**:
  - [ ] Generate search topics from org profiles dynamically
  - [ ] Add Sidekiq recurring job scheduling
  - [ ] Write `AgentTrace` records for audit trail

### A5. Source Discovery Agent
- **File**: `app/services/source_discovery_agent.rb`
- **Pattern**: Search → Visit → Classify pipeline
- **What it does**: Finds official regulatory data sources by googling → reading site → LLM classification
- **Strengths**: ✅ Uses `WebWalker` adapter. ✅ Suggests CSS selectors and ingestion types
- **Issues**:
  - ⚠️ Located outside `Ai::` module (inconsistent namespace)
  - ⚠️ No persistence of discovered sources — results ephemeral
- **Improvements**:
  - [ ] Move to `Ai::SourceDiscoveryAgent`
  - [ ] Auto-create `RegulatoryDataSource` records from verified discoveries
  - [ ] Use `ModelRouter`

### A6. Filter Agent
- **File**: `app/services/ai/filter_agent.rb`
- **Pattern**: Binary YES/NO classifier
- **What it does**: Asks LLM if a document is a regulation vs. noise (job posting, news, etc.)
- **Strengths**: ✅ Simple, focused. ✅ Fails open (allows through on error)
- **Issues**:
  - ❌ One LLM call **per candidate** — very expensive for batch filtering
  - ❌ Uses default model for a task ideal for `flash-lite`
- **Improvements**:
  - [ ] Batch multiple candidates into a single LLM call
  - [ ] Use `gemini-2.0-flash-lite` for this simple classification
  - [ ] Add caching by URL to avoid re-checking known items

### A7. Impact Analysis Agent
- **File**: `app/services/ai/impact_analysis_agent.rb`
- **Pattern**: Analysis + DB persistence
- **What it does**: Scores regulation relevance (0-100) against org profile, saves to `OrganizationRegulation`
- **Strengths**: ✅ Uses `gemini-1.5-pro` for reasoning. ✅ Persists to DB. ✅ Profile fallback
- **Issues**:
  - ⚠️ Truncates regulation to 5000 chars — may miss critical sections
  - ⚠️ `analyze_impact_for_all_orgs` iterates ALL orgs sequentially — no parallelism
- **Improvements**:
  - [ ] Use background jobs for per-org analysis (parallelize via Sidekiq)
  - [ ] Implement chunked analysis for long regulations
  - [ ] Write `AgentTrace` records

### A8. Policy Writer Agent
- **File**: `app/services/ai/agents/policy_writer_agent.rb`
- **Pattern**: RAG-enhanced generation
- **What it does**: Searches internal regulations via `RegulationSearchTool` (vector search), then drafts a policy
- **Strengths**: ✅ Grounded in actual regulatory data. ✅ Clean section structure
- **Issues**:
  - ⚠️ Returns raw markdown — no structured output
  - ❌ No length control or model selection
- **Improvements**:
  - [ ] Return structured output (title, sections hash, metadata)
  - [ ] Use `ModelRouter` (this is a "drafting" task)
  - [ ] Add org-specific context (industry, jurisdiction) to prompts

### A9. Policy Reviewer Agent
- **File**: `app/services/ai/agents/policy_reviewer_agent.rb`
- **Pattern**: RAG + structured evaluation
- **What it does**: Reviews draft policy against regulations, returns score + findings JSON
- **Strengths**: ✅ Structured JSON output with severity. ✅ Good key normalization
- **Issues**:
  - ⚠️ Uses same search as writer — review may be biased toward same sources
  - ⚠️ No rubric customization per framework
- **Improvements**:
  - [ ] Diversify search (different query or additional sources)
  - [ ] Allow framework-specific review rubrics
  - [ ] Persist review results to DB for trend tracking

### A10. Requirement Splitting Agent
- **File**: `app/services/ai/agents/requirement_splitting_agent.rb`
- **Pattern**: Text → structured data extraction
- **What it does**: Extracts individual requirements from regulation text
- **Strengths**: ✅ Handles both array and object response formats
- **Issues**:
  - ❌ No chunking for long texts — sends entire text in one prompt
  - ⚠️ No confidence scoring per requirement
- **Improvements**:
  - [ ] Chunk long texts and merge results
  - [ ] Add confidence per extracted requirement
  - [ ] Dedup against existing requirements before creating new ones

### A11. Metadata Extractor Agent
- **File**: `app/services/ai/agents/metadata_extractor_agent.rb`
- **Pattern**: Text → structured metadata
- **What it does**: Extracts jurisdiction, agency, dates, keywords, sector, risk level
- **Strengths**: ✅ Comprehensive schema. ✅ Clean error handling
- **Issues**:
  - ❌ **Duplicates** `RegulationProcessorService.extract_metadata` — same work done in two places
- **Improvements**:
  - [ ] Consolidate with `RegulationProcessorService` — make this THE metadata extractor
  - [ ] Remove duplicate logic from `RegulationProcessorService`

### A12. Regulation Extraction Service
- **File**: `app/services/regulation_extraction_service.rb`
- **Pattern**: Custom column extraction with caching
- **What it does**: Uses dynamic `CustomColumn.prompt` to ask LLM specific questions about a regulation
- **Strengths**: ✅ Staleness checking. ✅ Confidence scoring. ✅ Source text citation
- **Issues**:
  - ⚠️ Falls back to `confidence: 0.5` for non-JSON responses — may be too generous
  - ⚠️ Outside `Ai::` namespace
- **Improvements**:
  - [ ] Move to `Ai::` namespace
  - [ ] Lower fallback confidence to 0.2
  - [ ] Use shared JSON parsing utility

### A13. Regulation Processor Service
- **File**: `app/services/regulation_processor_service.rb`
- **Pattern**: Full pipeline — clean → extract → save → embed → create requirements
- **What it does**: Main regulation processing workhorse (metadata + requirements in one LLM call)
- **Strengths**: ✅ Triggers embeddings. ✅ Creates `StandardRequirement` records. ✅ Complete pipeline
- **Issues**:
  - ❌ **Duplicates** `MetadataExtractorAgent` + `RequirementSplittingAgent` — doing same work independently
  - ⚠️ One massive prompt combining metadata + requirements extraction
- **Improvements**:
  - [ ] Refactor to delegate to `MetadataExtractorAgent` + `RequirementSplittingAgent` (use `RegulationSupervisor`)
  - [ ] Remove inline LLM call, become an orchestrator only

### A14. Regulatory Scraper Service (2 LLM calls)
- **File**: `app/services/regulatory_scraper_service.rb`
- **LLM Call 1** — `extract_content_with_llm`: Extracts title/date/text from HTML pages
- **LLM Call 2** — `extract_links_with_llm`: Identifies regulation links from HTML
- **Strengths**: ✅ Smart ETag/Last-Modified caching. ✅ Content drift detection via SHA256. ✅ Multi-format (PDF, DOCX, HTML)
- **Issues**:
  - ⚠️ Sends raw HTML to LLM — can be very large/expensive
  - ⚠️ No HTML truncation strategy before LLM call
- **Improvements**:
  - [ ] Pre-clean and truncate HTML before sending to LLM
  - [ ] Use `Nokogiri` to extract `<main>` or `<article>` content first
  - [ ] Add token estimation before calling LLM

### A15. Smart Configurator Service
- **File**: `app/services/regulatory/smart_configurator_service.rb`
- **Pattern**: Documentation → configuration
- **What it does**: Reads API docs, generates scraper config (results_key, title_key, etc.)
- **Strengths**: ✅ Preview before apply. ✅ Good prompt structure
- **Issues**:
  - ⚠️ Truncates docs to 3000 chars — may miss important fields
  - ⚠️ No JS rendering fallback for SPAs
- **Improvements**:
  - [ ] Increase doc limit or chunk
  - [ ] Use shared JSON parsing utility
  - [ ] Move to `Ai::` namespace

### A16. Model Router
- **File**: `app/services/ai/model_router.rb`
- **Pattern**: Meta-LLM — uses LLM to classify task type and select model
- **What it does**: Classifies query as analysis/drafting/coding/factual, maps to model
- **Strengths**: ✅ Good architecture for cost optimization. ✅ Uses cheapest model for classification
- **Issues**:
  - ❌ **DEAD CODE** — not used by any other service. Every feature hardcodes its model or uses default
- **Improvements**:
  - [ ] Integrate into all services via a shared `Ai::Client` wrapper
  - [ ] Add token/cost tracking per category

### A17. Embedding Service
- **File**: `app/services/ai/embedding_service.rb`
- **Pattern**: Thin wrapper around `RubyLLM.embed`
- **What it does**: Generates vector embeddings for semantic search
- **Strengths**: ✅ Used by `RegulationSearchTool`. ✅ Both instance and class methods
- **Issues**:
  - ⚠️ No batching support
  - ⚠️ No dimensionality validation
- **Improvements**:
  - [ ] Add batch embedding method for bulk operations
  - [ ] Validate embedding dimensions match pgvector column config
  - [ ] Add caching for repeated texts

---

## Supporting Infrastructure

| Component | File | Status |
|---|---|---|
| **RegulationSupervisor** | `ai/regulation_supervisor.rb` | ✅ Runs `MetadataExtractor` + `RequirementSplitter` in parallel via `Async`. **Duplicates** `RegulationProcessorService` |
| **DiscoverySupervisor** | `ai/discovery_supervisor.rb` | ✅ Dispatches `OfficialRegisterScout` → `FilterAgent` → ingestion |
| **OrchestratorAgent** | `ai/orchestrator_agent.rb` | ✅ Chains `PolicyWriter` → `PolicyReviewer`. No self-healing loop yet |
| **GoogleSearchTool** | `ai/tools/google_search_tool.rb` | ⚠️ Has simulated fallback (test data when no API key) |
| **WebReaderTool** | `ai/tools/web_reader_tool.rb` | ✅ Clean. Truncates to 20K chars |
| **RegulationSearchTool** | `ai/regulation_search_tool.rb` | ✅ Best tool — grounds LLM in real data via pgvector |
| **AgentTrace model** | `app/models/ai/agent_trace.rb` | ⚠️ Model exists but **no service currently writes traces** |

---

## PART B: Keyword-Matching Features to Upgrade (6)

### B1. Impact Prediction Service
- **File**: `app/services/impact_prediction_service.rb`
- **Current**: Word overlap scoring to find impacted controls/policies/obligations
- **Upgrade**:
  - [ ] Use `RubyLLM.chat.ask` to semantically analyze regulation text against each control
  - [ ] Use embeddings + cosine similarity for initial filtering, LLM for detailed analysis
  - [ ] Generate natural language explanations of impact per item

### B2. Questionnaire Autofill Service
- **File**: `app/services/questionnaire_autofill_service.rb`
- **Current**: Keyword-matches questions to policies, templates answers from policy text
- **Upgrade**:
  - [ ] Use `RubyLLM.chat.ask` to generate contextual answers grounded in policy documents
  - [ ] Use `RegulationSearchTool` / embeddings to find relevant policies
  - [ ] Generate professional, natural language answers per question

### B3. Policy Gap Analysis Service (Draft)
- **File**: `app/services/policy_gap_analysis_service.rb`
- **Current**: Static template-based policy body generation
- **Upgrade**:
  - [ ] Use `PolicyWriterAgent` to generate real AI-drafted policies for gaps
  - [ ] Ground drafts in actual regulation text and org context
  - [ ] Use `PolicyReviewerAgent` to auto-score drafts before presenting

### B4. Executive Report Narrative
- **File**: `app/services/executive_report_service.rb`
- **Current**: String interpolation (heredoc template) with metrics values
- **Upgrade**:
  - [ ] Use `RubyLLM.chat.ask` to generate executive-quality narrative from metrics
  - [ ] Add trend analysis ("findings decreased 20% compared to last quarter")
  - [ ] Generate actionable recommendations per section

### B5. Harmonization Suggestions
- **File**: `app/services/harmonization_service.rb`
- **Current**: Keyword extension matching across frameworks
- **Upgrade**:
  - [ ] Use embeddings to find semantically similar requirements across frameworks
  - [ ] Use LLM to explain WHY a control maps to a requirement
  - [ ] Generate confidence-scored mapping suggestions

### B6. Maturity Scoring Commentary
- **File**: `app/services/maturity_scoring_service.rb`
- **Current**: Deterministic weighted formula (testing 30%, evidence 25%, findings 25%, docs 20%)
- **Upgrade**:
  - [ ] Keep formula for scoring (deterministic is correct here)
  - [ ] Add LLM-generated commentary and recommendations per control
  - [ ] Generate improvement roadmap suggestions based on gap analysis

---

## PART C: Cross-Cutting Infrastructure Improvements

### C1. Shared AI Client Wrapper
- **Priority**: 🔴 HIGH
- **Problem**: Every service calls `RubyLLM.chat.ask()` directly with no standardization
- **Solution**:
  - [ ] Create `Ai::Client` class that wraps all LLM calls
  - [ ] Centralized logging, token tracking, rate limiting, retry logic
  - [ ] Integrate `ModelRouter` into the client
  - [ ] Add cost estimation per call

### C2. Shared JSON Parsing Utility
- **Priority**: 🔴 HIGH
- **Problem**: 10+ services duplicate `response.content.gsub(/```json|```/, '').strip` + `JSON.parse`
- **Solution**:
  - [ ] Create `Ai::ResponseParser` module
  - [ ] Handle markdown blocks, partial JSON, array vs object formats
  - [ ] Standardize `deep_transform_keys` + `deep_symbolize_keys`

### C3. AgentTrace Integration
- **Priority**: 🟡 MEDIUM
- **Problem**: `Ai::AgentTrace` model exists but nothing writes to it
- **Solution**:
  - [ ] Add trace recording to `Ai::Client` wrapper (automatic for all calls)
  - [ ] Record: model used, token count, latency, prompt hash, success/failure
  - [ ] Build admin dashboard for AI usage analytics

### C4. Token-Aware Context Management
- **Priority**: 🟡 MEDIUM
- **Problem**: Texts truncated by character count, not token count
- **Solution**:
  - [ ] Add token estimation (chars ÷ 4 as rough heuristic, or use tokenizer)
  - [ ] Implement sliding window context for long documents
  - [ ] Add context budget per prompt

### C5. Namespace Consolidation
- **Priority**: 🟢 LOW
- **Problem**: Some services inside `Ai::`, some outside (`AiSearchService`, `SourceDiscoveryAgent`, `RegulationExtractionService`)
- **Solution**:
  - [ ] Move all AI services under `Ai::` namespace
  - [ ] Standardize naming: `Ai::Search::QueryExpander`, `Ai::Source::DiscoveryAgent`, etc.

### C6. Pipeline Deduplication
- **Priority**: 🟡 MEDIUM
- **Problem**: `RegulationProcessorService` duplicates `MetadataExtractorAgent` + `RequirementSplittingAgent`
- **Solution**:
  - [ ] Make `RegulationProcessorService` delegate to `RegulationSupervisor`
  - [ ] Remove inline LLM call from `RegulationProcessorService`
  - [ ] Single source of truth for regulation processing

### C7. Batch Operations
- **Priority**: 🟢 LOW
- **Problem**: `FilterAgent` makes one LLM call per candidate; embeddings have no batching
- **Solution**:
  - [ ] Add batch methods to `FilterAgent` and `EmbeddingService`
  - [ ] Group candidates into single prompt for bulk classification

---

## Sprint Checklist Summary

### Infrastructure (do first)
- [ ] C1 — Create `Ai::Client` wrapper
- [ ] C2 — Create `Ai::ResponseParser` utility
- [ ] C3 — Integrate `AgentTrace` recording
- [ ] C6 — Deduplicate regulation processing pipelines

### Upgrade Keyword → LLM (Part B)
- [ ] B4 — Executive Report Narrative (highest user-facing impact)
- [ ] B2 — Questionnaire Autofill answers
- [ ] B1 — Impact Prediction semantic analysis
- [ ] B3 — Policy Gap draft generation
- [ ] B5 — Harmonization suggestions via embeddings
- [ ] B6 — Maturity commentary

### Improve Existing Features (Part A — priority items)
- [ ] A1 — Extract Compliance Assistant to service + add memory
- [ ] A6 — Batch FilterAgent calls
- [ ] A16 — Activate ModelRouter across all services
- [ ] A11/A13 — Consolidate MetadataExtractor and RegulationProcessor

### Polish & Optimization
- [ ] C4 — Token-aware context management
- [ ] C5 — Namespace consolidation
- [ ] C7 — Batch operations for embeddings + filtering
- [ ] A2 — Add caching to AI Search
- [ ] A3/A4/A7 — Write AgentTraces for all agents
