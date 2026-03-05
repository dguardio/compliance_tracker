# Python Scrapling Service Integration Design

## Overview
This document outlines the architecture for integrating an autonomous Python web scraper (using the `scrapling` library) into the existing Ruby on Rails `compliance_tracker` application.

## Goal
To delegate complex, multi-level web scraping (which requires JavaScript rendering and intelligent DOM navigation) to a separate Python microservice, while maintaining all scheduling, state management, and business logic within the core Rails application.

## Architecture Request
The user selected **Option A: Rails-Driven (Push)**.

### Data Flow
1. **Trigger:** The existing `RegulatoryScraperService` running on a Sidekiq cron schedule selects a `RegulatoryDataSource` that is flagged to use the external Python scraper.
2. **Push:** Rails sends an HTTP POST request containing the target URL and extraction instructions to the Python Microservice API.
3. **Execution:** The Python service uses `scrapling` (Playwright + LLM) to navigate the site, bypass protections, find the deep document links, and extract the raw text or markdown.
4. **Response:** 
    - *Synchronous Route (Small documents):* Python returns the extracted JSON directly in the HTTP response.
    - *Asynchronous Webhook Route (Large documents):* Python immediately returns a `202 Accepted` status. Once scraping completes, Python sends an HTTP POST webhook back to a new Rails endpoint (`/api/v1/ingestions/webhook`) containing the extracted data.
5. **Ingestion:** Rails receives the data (either from the sync response or the webhook), creates the `Regulation` record, and enqueues the `VectorizeChunkJob` to embed the text via PgVector.

## Components

### 1. Rails Enhancements
- **Model Update:** Add a new `scraping_engine` enum or string to `RegulatoryDataSource` (e.g., `'internal_nokogiri'`, `'external_scrapling'`).
- **Service Update:** Modify `RegulatoryScraperService` to route requests to the external Python API when the engine is `external_scrapling`.
- **API Endpoint:** Create an unauthenticated (or token-auth'd) endpoint `POST /api/v1/ingestions/webhook` to receive asynchronous results from the Python service.

### 2. Python Microservice
- **Framework:** FastAPI (for high-performance, async API handling).
- **Core Library:** `scrapling` (for adaptive playright/LLM web scraping).
- **Endpoints:**
    - `POST /scrape` -> Accepts `{ "url": "...", "callback_url": "..." }`
- **Infrastructure:** Dockerized container that can run alongside the Rails app, with Chrome/Playwright binaries installed.

## Trade-offs and Considerations
- **Pros:** Keeps heavy Playwright runtime out of the Rails worker pool. Leverages Python's superior ML/LLM library ecosystem (`scrapling`).
- **Cons:** Adds a new language, repository, and deployment artifact to the stack. Requires network communication between containers.
- **Error Handling:** If Python fails, the webhook will return an error status, allowing Rails to mark the `RegulatoryDataSource` sync as failed and retry gracefully via Sidekiq.

## Verification Plan
1. Stand up a mockup FastAPI server locally returning static JSON.
2. Update `RegulatoryScraperService` to send a request to the local mockup.
3. Verify Rails successfully parses the JSON and creates a `Regulation` record.
4. (Separate Phase) Build the actual Python `scrapling` Docker image and deploy it.
