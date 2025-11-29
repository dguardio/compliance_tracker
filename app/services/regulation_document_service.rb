class RegulationDocumentService
  def attach_document(regulation)
    # Check if a document already exists for this regulation
    return if Document.where(regulation: regulation).exists?

    # Try to fetch from existing URL
    if (url = find_file_url(regulation))
      create_document_from_url(regulation, url)
    else
      # Generate PDF if no file exists
      create_generated_document(regulation)
    end
  rescue StandardError => e
    Rails.logger.error "Failed to create document for regulation #{regulation.id}: #{e.message}"
  end

  private

  def find_file_url(regulation)
    # Prioritize PDF, then HTML, then any other
    regulation.files['pdf'] || regulation.files['html'] || regulation.files.values.first
  end

  def system_user
    # Fallback to the first user if no specific system user exists
    @system_user ||= User.find_by(email: 'system@example.com') || User.order(:created_at).first
  end

  def create_document_from_url(regulation, url)
    Rails.logger.info "Creating document from URL: #{url}"
    
    begin
      require 'open-uri'
      downloaded_file = URI.open(url)
      filename = File.basename(URI.parse(url).path)
      filename = "regulation_#{regulation.id}.pdf" if filename.blank?
      
      document = Document.new(
        title: regulation.title,
        description: "Source document for #{regulation.title}",
        category: 'Regulation',
        status: :approved,
        uploaded_by: system_user,
        regulation: regulation,
        organization: nil # Global document
      )
      
      document.file.attach(
        io: downloaded_file,
        filename: filename
      )
      
      document.save!
    rescue => e
      Rails.logger.warn "Failed to download file from #{url}: #{e.message}. Falling back to generation."
      create_generated_document(regulation)
    end
  end

  def create_generated_document(regulation)
    Rails.logger.info "Generating PDF document for regulation #{regulation.id}"
    
    pdf_content = WickedPdf.new.pdf_from_string(
      render_html(regulation),
      title: regulation.title,
      margin: { top: 10, bottom: 10, left: 10, right: 10 }
    )
    
    document = Document.new(
      title: regulation.title,
      description: "Auto-generated document for #{regulation.title}",
      category: 'Regulation',
      status: :approved,
      uploaded_by: system_user,
      regulation: regulation,
      organization: nil # Global document
    )
    
    document.file.attach(
      io: StringIO.new(pdf_content),
      filename: "regulation_#{regulation.id}_generated.pdf",
      content_type: 'application/pdf'
    )
    
    document.save!
  end

  def render_html(regulation)
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { font-family: sans-serif; line-height: 1.6; }
          h1 { color: #333; border-bottom: 2px solid #333; padding-bottom: 10px; }
          .metadata { background: #f5f5f5; padding: 15px; margin-bottom: 20px; border-radius: 5px; }
          .metadata p { margin: 5px 0; }
          .content { white-space: pre-wrap; }
        </style>
      </head>
      <body>
        <h1>#{regulation.title}</h1>
        
        <div class="metadata">
          <p><strong>Agency:</strong> #{regulation.agency}</p>
          <p><strong>Jurisdiction:</strong> #{regulation.jurisdiction}</p>
          <p><strong>Effective Date:</strong> #{regulation.effective_date}</p>
          <p><strong>Type:</strong> #{regulation.reg_type}</p>
        </div>
        
        <div class="content">
          #{regulation.full_text['extracted_content'] || regulation.full_text['main'] || regulation.full_text.to_s}
        </div>
      </body>
      </html>
    HTML
  end
end
