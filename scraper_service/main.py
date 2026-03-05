import time
import requests
import json
from fastapi import FastAPI, BackgroundTasks, Depends, HTTPException
from pydantic import BaseModel
import logging
from sqlalchemy.orm import Session
from database import engine, Base, get_db
import models
from scraper import extract_regulation_data

# Create tables
Base.metadata.create_all(bind=engine)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Python Scrapling Service")

class ScrapeRequest(BaseModel):
    url: str
    data_source_id: int
    webhook_url: str
    provider_name: str
    jurisdiction: str

class ScrapeResponse(BaseModel):
    job_id: int
    status: str
    message: str

def process_scrape(job_id: int, request: ScrapeRequest):
    # This runs in a background thread
    db = Session(bind=engine)
    job = db.query(models.ScrapeJob).filter(models.ScrapeJob.id == job_id).first()
    
    if not job:
        db.close()
        return

    try:
        logger.info(f"Job {job_id}: Starting extraction for {request.url}")
        
        # Call the core Scrapling extraction logic
        extracted_data = extract_regulation_data(
            url=request.url, 
            provider_name=request.provider_name,
            jurisdiction=request.jurisdiction
        )
        
        # Prepare the Webhook payload
        payload = {
            "url": request.url,
            "data_source_id": request.data_source_id,
            "title": extracted_data["title"],
            "publication_date": extracted_data["publication_date"],
            "content": extracted_data["content"]
        }
        
        # Save success to local DB
        job.status = "success"
        job.result_payload = json.dumps(payload)
        db.commit()
        
        # Fire the webhook back to Rails
        logger.info(f"Job {job_id}: Scrape completed, posting back to {request.webhook_url}")
        response = requests.post(request.webhook_url, json=payload, timeout=30)
        
        if not response.ok:
             logger.error(f"Job {job_id}: Webhook failed with status {response.status_code}: {response.text}")
        else:
             logger.info(f"Job {job_id}: Webhook delivered successfully.")

    except Exception as e:
        logger.error(f"Job {job_id}: Scraping failed: {str(e)}")
        job.status = "failed"
        job.error_message = str(e)
        db.commit()
    finally:
        db.close()


@app.post("/scrape", response_model=ScrapeResponse)
async def start_scrape(request: ScrapeRequest, background_tasks: BackgroundTasks, db: Session = Depends(get_db)):
    logger.info(f"Received scrape request for {request.url}")
    
    # 1. Create the ScrapeJob in the database
    new_job = models.ScrapeJob(
        url=request.url,
        data_source_id=request.data_source_id,
        webhook_url=request.webhook_url,
        provider_name=request.provider_name,
        jurisdiction=request.jurisdiction,
        status="pending"
    )
    db.add(new_job)
    db.commit()
    db.refresh(new_job)
    
    # 2. Add the background task to execute the scrape and send the webhook
    background_tasks.add_task(process_scrape, new_job.id, request)
    
    return ScrapeResponse(
        job_id=new_job.id, 
        status="accepted", 
        message="Scraping job started in background"
    )

@app.get("/jobs/{job_id}")
def get_job_status(job_id: int, db: Session = Depends(get_db)):
    job = db.query(models.ScrapeJob).filter(models.ScrapeJob.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    
    return {
        "job_id": job.id,
        "url": job.url,
        "status": job.status,
        "error_message": job.error_message
    }
