# Python Scrapling Integration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Integrate a separate Python `scrapling` microservice by adding an API webhook endpoint to Rails and updating the `RegulatoryScraperService` to dispatch jobs to it.

**Architecture:** We are using a push-based webhook approach. The Rails `RegulatoryScraperService` will POST the target URL to the Python service. When the Python service finishes deep-scraping, it will POST the extracted JSON back to a new `IngestionsController` in Rails, which will save the `Regulation` and enqueue the embedding job.

**Tech Stack:** Ruby on Rails, PostgreSQL, Sidekiq, Python (FastAPI + scrapling - *mocked for this implementation phase*).

---

### Task 1: Update RegulatoryDataSource schema
Add the `scraping_engine` configuration to the `settings` JSONB column (or add a dedicated enum column if preferred) to differentiate between the internal Nokogiri scraper and the external Python scraper.

**Files:**
- Modify: `app/models/regulatory_data_source.rb`
- Test: `test/models/regulatory_data_source_test.rb` (create if doesn't exist)

**Step 1: Write the failing test**
Ensure that a data source can be configured to use the external engine.

**Step 2: Run test to verify it fails**
Run the model test. Expected: FAIL.

**Step 3: Write minimal implementation**
Update the model to include a helper method or validation for `scraping_engine` (e.g., `def external_scraper?; settings['scraping_engine'] == 'external'; end`).

**Step 4: Run test to verify it passes**
Run the model test. Expected: PASS.

**Step 5: Commit**
Commit the model changes.

---

### Task 2: Create the Webhook API Endpoint
Create the endpoint that the Python service will hit to deliver the scraped payload.

**Files:**
- Create: `app/controllers/api/v1/ingestions_controller.rb`
- Modify: `config/routes.rb`
- Test: `test/controllers/api/v1/ingestions_controller_test.rb`

**Step 1: Write the failing test**
Write a controller test that POSTs a mock Scrapling JSON payload to `/api/v1/ingestions` and asserts that a `Regulation` is created.

**Step 2: Run test to verify it fails**
Run the controller test. Expected: FAIL (RoutingError).

**Step 3: Write minimal implementation**
1. Add `post 'ingestions', to: 'ingestions#create'` to the `api/v1` namespace in `routes.rb`.
2. Create `IngestionsController` with a `create` action that parses the JSON, finds the associated `RegulatoryDataSource`, creates the `Regulation` (handling versions/revisions), and enqueues `VectorizeChunkJob`.

**Step 4: Run test to verify it passes**
Run the controller test. Expected: PASS.

**Step 5: Commit**
Commit the routing and controller changes.

---

### Task 3: Update RegulatoryScraperService
Modify the scraper service to route URLs to the Python service instead of scraping locally if `external_scraper?` is true.

**Files:**
- Modify: `app/services/regulatory_scraper_service.rb`
- Test: `test/services/regulatory_scraper_service_test.rb` (or equivalent test file)

**Step 1: Write the failing test**
Write a test simulating an external data source and assert that `HTTParty.post` is called to the external Python service URL instead of `IngestRegulationLinkJob`.

**Step 2: Run test to verify it fails**
Run the service test. Expected: FAIL.

**Step 3: Write minimal implementation**
Update `dispatch_links` or `scrape_website` to check `data_source.external_scraper?`. If true, make a POST request to `ENV['SCRAPLING_SERVICE_URL'] || 'http://localhost:8000/scrape'` with the target URL and the Rails webhook URL (`ENV['APP_URL'] + '/api/v1/ingestions'`).

**Step 4: Run test to verify it passes**
Run the service test. Expected: PASS.

**Step 5: Commit**
Commit the service updates.

---

### Task 4: Setup Python Mock (For local testing)
Create a simple Python FastAPI mock to simulate the Scrapling service during local development.

**Files:**
- Create: `scraper_service/main.py`
- Create: `scraper_service/requirements.txt`

**Step 1: Create the mockup**
Write a very basic FastAPI application that exposes `POST /scrape`, waits 2 seconds, and then POSTs a dummy JSON payload back to the provided `callback_url`.

**Step 2: Document how to run it**
Add instructions to the project README on how to run the mock service alongside Rails (e.g., `cd scraper_service && uvicorn main:app`).

**Step 3: Commit**
Commit the mock service code.
