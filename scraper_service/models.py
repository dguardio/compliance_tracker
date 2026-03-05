from sqlalchemy import Column, Integer, String, Text, DateTime
from datetime import datetime, timezone
from database import Base

class ScrapeJob(Base):
    __tablename__ = "scrape_jobs"

    id = Column(Integer, primary_key=True, index=True)
    url = Column(String, index=True, nullable=False)
    data_source_id = Column(Integer, nullable=False)
    webhook_url = Column(String, nullable=False)
    provider_name = Column(String, nullable=False)
    jurisdiction = Column(String, nullable=False)
    
    status = Column(String, default="pending")  # pending, success, failed
    result_payload = Column(Text, nullable=True)  # JSON string
    error_message = Column(Text, nullable=True)
    
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
