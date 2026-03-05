# Compliance Tracker

A comprehensive compliance management application built with Ruby on Rails.

## Features

- Multi-organization support with tenant isolation
- Document management with version control
- Compliance framework management
- Risk assessment and tracking
- User role management and permissions
- Real-time notifications
- Document preview for multiple file types

## Document Preview Support

The application supports in-app preview for the following file types:

- **Images**: JPEG, PNG, GIF
- **PDFs**: Using PDF.js viewer
- **Text files**: Plain text and CSV
- **Word documents**: DOC and DOCX (using docx gem and docsplit for older formats)
- **Excel spreadsheets**: XLS and XLSX (using roo and creek gems)
- **PowerPoint presentations**: PPT and PPTX (using docsplit for conversion)

## System Dependencies

For document preview functionality, you'll need to install the following system dependencies:

### Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y \
  poppler-utils \
  tesseract-ocr \
  tesseract-ocr-eng \
  libreoffice \
  ghostscript \
  imagemagick
```

### macOS:
```bash
brew install poppler tesseract tesseract-lang libreoffice ghostscript imagemagick
```

### CentOS/RHEL:
```bash
sudo yum install -y poppler-utils tesseract tesseract-langpack-eng libreoffice ghostscript ImageMagick
```

## Installation

1. Clone the repository
2. Install Ruby dependencies: `bundle install`
3. Install system dependencies (see above)
4. Set up the database: `rails db:create db:migrate db:seed`
5. Start the server: `rails server`

## Usage

Visit `http://localhost:3000` to access the application.

## Local Python Scraper Mock

To test the Scrapling integration locally, run the Python Mock FastAPI service:

```bash
cd scraper_service
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --port 8000 --reload
```

This will run a background mock service on port 8000 that the `RegulatoryScraperService` can dispatch to.

## License

This project is licensed under the MIT License.
