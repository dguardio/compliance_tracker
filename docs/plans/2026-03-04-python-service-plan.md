# Python Scrapling Service Implementation Plan

**Goal:** Build a fully functional Python Scrapling microservice within the `scraper_service/` directory. This service will eventually be extracted to its own repository, but for now, we will build and test it here.

## Tech Stack
- **Framework:** FastAPI
- **Database:** SQLite (using SQLAlchemy ORM) - SQLite is perfect for this stage; it can easily be swapped for PostgreSQL when extracting.
- **Scraping Engine:** `scrapling` (Python library for adaptive scraping)
- **Background Jobs:** FastAPI's built-in `BackgroundTasks` (sufficient for initial architecture; easily upgradable to Celery/ARQ later).

## Architecture

1. **Database Models**
   - `ScrapeJob`: Tracks the state of a scraping request.
     - `id`, `url`, `data_source_id`, `webhook_url`, `status` (pending, success, failed), `result_payload`, `error_message`, `created_at`, `updated_at`.

2. **Endpoints**
   - `POST /scrape`: Accepts the payload from Rails, creates a `ScrapeJob` (status: pending) in the DB, and dispatches a background task. Returns the `job_id`.
   - `GET /jobs/{job_id}`: (Optional) Allows checking the status of a specific job.

3. **Core Scraping Logic (`scraper.py`)**
   - Uses `scrapling` to retrieve the web page.
   - Extracts the title, publication date (if available), and full text.
   - We will implement a robust extraction strategy using `scrapling`'s text extraction capabilities, potentially combined with `litellm` or `openai` if LLM fallback is needed (as `scrapling` supports).

4. **Webhook Dispatcher**
   - Once the scraping background task finishes, it updates the `ScrapeJob` in the DB.
   - It then uses `requests` to POST the extracted data back to the `webhook_url` provided by Rails.

## Implementation Steps

- [ ] **Step 1:** Setup Python environment & Dependencies (SQLAlchemy, Scrapling, etc.)
- [ ] **Step 2:** Create the Database configuration and SQLAlchemy Models (`database.py`, `models.py`)
- [ ] **Step 3:** Implement the Scrapling extraction logic (`scraper.py`)
- [ ] **Step 4:** Implement FastAPI Endpoints and Background Tasks (`main.py`)
- [ ] **Step 5:** End-to-End local testing with the Rails app.
