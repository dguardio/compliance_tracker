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
        title = page.css("title").text()
        
        if not title:
            h1 = page.css("h1")
            title = h1[0].text() if h1 else f"Regulation from {provider_name}"
            
        # Clean up title
        title = title.strip().replace("\n", " ") if title else title
            
        # Extract main text
        # If the page has an 'article', 'main', or '.content' tag, we prefer that.
        content = ""
        main_content = page.css("article, main, .content, #content, .main-content")
        
        if main_content:
            # Join text of all matching main blocks
            # scrapling returns ScraplingElement objects which have a .text() method
            content = "\n\n".join(node.text() for node in main_content)
        else:
            # Fallback to body text
            body = page.css("body")
            content = body[0].text() if body else page.text()
            
        # Clean up content a bit
        content = content.replace("  ", " ").strip() if content else ""
        
        # Scrapling doesn't natively extract 'publication_date' magically without LLMs
        # so we default it or try to find a time tag.
        pub_date = None
        time_tag = page.css("time")
        if time_tag:
            pub_date = time_tag[0].attrib.get('datetime') or time_tag[0].text()
            
        if not pub_date:
            # Default to today if we must, or leave None
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
