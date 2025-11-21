# Project TODOs

## Development Roadmap

*   **Phase 1: Automated Ingestion and AI-powered processing of regulations. (COMPLETED)**
*   **Phase 2: Stakeholder Review and Decision Workflow. (COMPLETED)**
*   **Phase 3: Implementation, Task Management, and Reporting. (COMPLETED)**
*   **Phase 4: Advanced Analytics and Integrations. (PENDING)**
*   **Phase 5: Advanced Regulatory Data Ingestion by Sector (Future Refinement)**

---

## Phase 5: Advanced Regulatory Data Ingestion by Sector

This plan outlines a future refinement to the regulatory data ingestion process, moving from a source-specific approach to a more comprehensive, sector-based approach.

**Sub-Phase 1: Discovery and Curation of Data Sources**

1.  **Automated Source Discovery:**
    *   Develop a "Source Discovery Agent" that uses web search and LLMs to find relevant regulatory bodies, government agencies, and other sources of regulatory information for a given sector and jurisdiction.
    *   The agent would take a sector (e.g., "Healthcare", "Finance") and a jurisdiction (e.g., "USA", "EU") as input and return a list of potential data sources (websites, RSS feeds, API endpoints).
    *   The agent would also attempt to identify the type of each source (e.g., `web_scrape`, `rss`, `api`).

2.  **Source Curation and Management:**
    *   Enhance the `RegulatoryDataSource` model to store more metadata about each source, such as the sectors and jurisdictions it covers.
    *   Build a UI for administrators to review, approve, and curate the discovered data sources.
    *   The UI would allow administrators to manually add, edit, and tag data sources with relevant sectors and jurisdictions.

**Sub-Phase 2: Intelligent and Adaptive Data Ingestion**

1.  **Generic Scraper with Adaptive Parsing:**
    *   Refactor the `RegulatoryScraperService` to be more generic and adaptive.
    *   Instead of relying on a specific CSS selector, the scraper would use an LLM to analyze the structure of a webpage and identify the relevant content to extract (e.g., the main body of a regulation, its title, publication date, etc.).
    *   The scraper would be able to handle a wider variety of website layouts and structures without needing to be reconfigured for each source.

2.  **Multi-Modal Data Ingestion:**
    *   Extend the scraper to handle different types of content, including PDFs, Word documents, and other common formats.
    *   Integrate with document processing libraries and services to extract text and metadata from these files.
    *   For sources that provide APIs, develop a flexible API client that can be configured to work with different API specifications.

**Sub-Phase 3: AI-Powered Processing and Enrichment**

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

**Sub-Phase 4: Scalability, Monitoring, and Continuous Improvement**

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