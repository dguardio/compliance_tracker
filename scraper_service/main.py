import time
import requests
from fastapi import FastAPI, BackgroundTasks
from pydantic import BaseModel
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Mock Scrapling Service")

class ScrapeRequest(BaseModel):
    url: str
    data_source_id: int
    webhook_url: str
    provider_name: str
    jurisdiction: str

def process_scrape(request: ScrapeRequest):
    # Simulate processing delay
    logger.info(f"Simulating scrape for URL: {request.url}")
    time.sleep(3)
    
    logger.info(f"Scrape completed, posting back to {request.webhook_url}")
    
    # Mock payload simulating Scrapling's smart extraction
    payload = {
        "url": request.url,
        "data_source_id": request.data_source_id,
        "title": f"Mock Regulation from {request.provider_name}",
        "publication_date": "2023-11-01",
        "content": "This is mock extracted text demonstrating the end-to-end integration between Rails and the Python Scrapling Service."
    }
    
    try:
        response = requests.post(request.webhook_url, json=payload, timeout=10)
        logger.info(f"Webhook response: {response.status_code}")
    except Exception as e:
        logger.error(f"Failed to call webhook: {str(e)}")


@app.post("/scrape")
async def start_scrape(request: ScrapeRequest, background_tasks: BackgroundTasks):
    logger.info(f"Received scrape request for {request.url}")
    background_tasks.add_task(process_scrape, request)
    return {"status": "accepted", "message": "Scraping job started in background"}
