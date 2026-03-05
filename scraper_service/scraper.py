import json
import logging
from scrapling import Fetcher
from datetime import datetime

logger = logging.getLogger(__name__)

def extract_regulation_data(url: str, provider_name: str, jurisdiction: str) -> dict:
    """
    Fetches a web page using Scrapling and extracts regulation metadata & content.
    """
    logger.info(f"Starting Scrapling fetch for {url}")
    
    try:
        # Initialize Scrapling Fetcher (handles adaptive fetching and anti-bot bypassing)
        fetcher = Fetcher(auto_match=False)
        page = fetcher.get(url)
        
        # We can extract the main text using Scrapling's built-in intelligent extraction
        # But wait, Scrapling is a wrapper over Playwright/httpx with beautiful extractors.
        # Let's write custom CSS selectors for standard elements, or fall back to full text.
        
        # Extract title
        title = page.css("title::text").get()
        if not title:
            title = page.css("h1::text").get() or f"Regulation from {provider_name}"
            
        title = title.strip().replace("\n", " ") if title else title
            
        # Extract main text
        content_nodes = page.css("article *::text, main *::text, .content *::text, .main-content *::text").getall()
        
        if content_nodes:
            content = " ".join(t.strip() for t in content_nodes if t.strip())
        else:
            body_nodes = page.css("body *::text").getall()
            if body_nodes:
                content = " ".join(t.strip() for t in body_nodes if t.strip())
            else:
                content = "Could not extract text from this page."
            
        # Optional: Clean up large whitespaces
        content = " ".join(content.split())
        
        pub_date = page.css("time::attr(datetime)").get() or page.css("time::text").get()
        if not pub_date:
            pub_date = datetime.now().strftime("%Y-%m-%d")

        result = {
            "title": title,
            "publication_date": pub_date,
            "content": content
        }
        
        logger.info(f"Successfully extracted {len(content)} characters from {url}")
        return result
        
    except Exception as e:
        logger.error(f"Scraping failed for {url}: {str(e)}")
        raise e
