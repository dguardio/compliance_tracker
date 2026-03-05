# Scrapling Integration & Deployment Guide

This document outlines the architecture, testing flow, and future deployment strategy for the Python Scrapling Service integration with the Compliance Tracker Rails application.

## 1. Architecture Overview

To bypass sophisticated anti-bot protections on regulatory websites, we implemented an asynchronous webhook architecture using the adaptive Python fetching library **Scrapling**.

1. **Rails Dispatch:** When `RegulatoryScraperService` processes a data source configured with `scraping_engine: external_scrapling`, it stops local processing and POSTs the job details to the Python service.
2. **Python Processing:** The FastAPI Python service receives the request, stores a `ScrapeJob` record in its local SQLite database, and immediately returns a `200 OK` (Accepted).
3. **Background Scraping:** A background task in Python executes `scrapling` to fetch, render, and extract text and metadata from the target URL.
4. **Rails Webhook Delivery:** Upon completion, the Python service POSTs the extracted JSON data back to the Rails webhook endpoint (`/api/v1/ingestions/webhook`).
5. **Rails Ingestion:** `IngestionsController` receives the payload, creates or updates the `Regulation` record (with PaperTrail versioning), creates an `Ai::AgentTrace` for logging, and enqueues `GenerateEmbeddingJob` for pgvector indexing.

---

## 2. Local Testing Flow

To test the integration end-to-end locally:

**1. Start the Python Service**
```bash
cd .worktrees/scrapling-feature/scraper_service
source venv/bin/activate
uvicorn main:app --port 8000 --reload
```
*Runs on `http://127.0.0.1:8000`*

**2. Start the Rails Server**
```bash
cd .worktrees/scrapling-feature
bin/dev
```
*Runs on `http://localhost:3000`*

**3. Trigger a Scrape (Rails Console)**
```ruby
provider = Provider.find_or_create_by!(name: "Test Provider", jurisdiction: "US", country: "United States")
data_source = RegulatoryDataSource.find_or_create_by!(name: "Scrapling Integration Test") do |ds|
  ds.provider = provider
  ds.source_type = "web_scrape"
  ds.url = "https://example.com/test/regulations"
  ds.settings = { "scraping_engine" => "external_scrapling" }
end

RegulatoryScraperService.new.scrape_data_source(data_source)
```

**Verification Check:** You should see logs in both Python and Rails, and `Regulation.last.title` should yield the scraped data.

---

## 3. Extracting the Python Service to its Own Project

Currently, the Python service sits inside `scraper_service/`. For production, it needs to be its own repository.

### Extraction Steps
1. Create a new minimal Git repository (e.g., `compliance-scraper-service`).
2. Move the contents of `scraper_service/` (`main.py`, `scraper.py`, `models.py`, `database.py`, `requirements.txt`) into the new repository.
3. Remove the `scraper_service/` directory from the Rails project.
4. Add a `Dockerfile` for deployment:

```dockerfile
FROM python:3.12-slim

# Install system dependencies needed for Playwright and Browsers
RUN apt-get update && apt-get install -y \
    wget gnupg curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install Playwright browsers
RUN playwright install chromium
RUN playwright install-deps chromium

COPY . .
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Database Migration
When extracting, upgrade the database from SQLite to PostgreSQL if you need shared scale across multiple Python worker pods. 
1. Add `psycopg2-binary` to `requirements.txt`.
2. Change `SQLALCHEMY_DATABASE_URL` in `database.py` to read from an environment variable `DATABASE_URL`.

---

## 4. Deployment and Production Integration

### Deploying the Python Service
1. Configure your hosting provider (Render, Fly.io, AWS ECS, or Heroku) using the provided `Dockerfile`.
2. **Environment Variables needed in Python Production:**
   - `DATABASE_URL` (if upgrading to Postgres).

### Connecting Rails to Python in Production

In your Rails production environment, set these Environment Variables:

1. **`PYTHON_SCRAPER_URL`**: Point this to the deployed Python service (e.g., `https://api.scraper.mycompany.com/scrape`).
2. **`APP_WEBHOOK_URL`**: Point this to your production Rails webhook (e.g., `https://app.mycompany.com/api/v1/ingestions/webhook`).

Because the Rails service dynamically reads `ENV['PYTHON_SCRAPER_URL']` and sends `ENV['APP_WEBHOOK_URL']` in the JSON payload, **no code changes are required** when moving from local development to production. The Python service will naturally start delivering payloads to the production Rails server.

### Security Enhancements (Recommended for Prod)
- Add a Shared Secret: Currently, the webhook is open. Add a `WEBHOOK_SECRET` environment variable to both projects. Have Python pass it in the Headers of its webhook request, and have the Rails `IngestionsController` verify it before processing the payload.
