import os
import json
import logging
from scrapling import Fetcher
from datetime import datetime
from litellm import completion
from urllib.parse import urljoin

logger = logging.getLogger(__name__)

def evaluate_links_with_llm(links_data: list, provider_name: str) -> str:
    """
    Uses litellm (model agnostic router) to choose the best link to click from a list of links,
    focusing on finding the most recent or primary regulation document.
    """
    prompt = f"We are looking for compliance regulations for '{provider_name}'. " \
             f"Given these {len(links_data)} links, return the EXACT href string of the one best link we should follow to reach the regulation document. " \
             f"If you are already on the regulation page and shouldn't click away, return 'NONE'.\n" \
             f"Links JSON:\n{json.dumps(links_data)}"

    # Provide a default model, but typically set this via ENV variables 
    # e.g., 'claude-3-5-sonnet-20240620' or 'gemini/gemini-1.5-pro' or 'gpt-4o'
    model = os.environ.get("LLM_MODEL_NAME", "gpt-4o-mini")
    
    logger.info(f"Asking LLM provider ({model}) for link evaluation...")
    try:
        response = completion(
            model=model,
            messages=[
                {"role": "system", "content": "You are a regulatory link-finding agent. ONLY return the exact href string or 'NONE'. No markdown, no explanations."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.0
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        logger.error(f"LiteLLM routing failed: {e}. Falling back to NONE.")
        return "NONE"

def extract_regulation_data(url: str, provider_name: str, jurisdiction: str, depth=0, max_depth=2) -> dict:
    """
    Fetches a web page using Scrapling and optionally navigates deeper using LLM evaluation.
    Extracts regulation metadata & content.
    """
    logger.info(f"Starting fetch for {url} (Depth: {depth})")
    
    try:
        # We can enable the Playwright engine for automatic rendering instead of static
        # by passing auto_match=True or engine="playwright". By default Fetcher uses auto.
        fetcher = Fetcher(auto_match=True)
        page = fetcher.get(url)
        
        # 1. Gather links and let the LLM decide if we need to navigate deeper
        if depth < max_depth:
            all_links = page.css("a")
            # Create a curated list of links with text for the LLM to read
            links_data = []
            for a in all_links[:50]:  # Limit to 50 links to save context window
                href = a.attrib.get('href')
                text = a.text()
                if href and text and len(text.strip()) > 3:
                    links_data.append({"text": text.strip(), "href": href})
            
            if links_data:
                target_href = evaluate_links_with_llm(links_data, provider_name)
                
                if target_href != "NONE" and target_href in [l["href"] for l in links_data]:
                    # Make absolute URL
                    next_url = urljoin(url, target_href)
                    logger.info(f"LLM determined we should navigate deeper to: {next_url}")
                    # Recursively scrape the next page
                    return extract_regulation_data(next_url, provider_name, jurisdiction, depth + 1, max_depth)
        
        # 2. Extract final page data (Base Case)
        logger.info(f"Extracting regulation text from final destination URL: {url}")
        
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
