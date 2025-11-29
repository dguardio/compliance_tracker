# scripts/generate_valid_docs.rb
begin
  puts "Starting generation script..."
  org = Organization.first
  unless org
    puts "ERROR: No organization found!"
    exit 1
  end
  puts "Using Organization: #{org.name}"

  user = User.first
  unless user
    puts "ERROR: No user found!"
    exit 1
  end
  puts "Using User: #{user.email}"

  generator = DocumentGeneratorService.new(org)

  puts "Generating PDF..."
  pdf_doc = generator.generate_document('pdf', 101)
  if pdf_doc
    puts "Created PDF: #{pdf_doc.title} (ID: #{pdf_doc.id})"
  else
    puts "Failed to create PDF. Check logs."
  end

  puts "Generating Excel..."
  xlsx_doc = generator.generate_document('excel', 102)
  if xlsx_doc
    puts "Created Excel: #{xlsx_doc.title} (ID: #{xlsx_doc.id})"
  else
    puts "Failed to create Excel. Check logs."
  end

  # Now attach a valid PDF to a Regulation
  reg = Regulation.first
  if reg
    puts "Attaching valid PDF to Regulation #{reg.id}..."
    # Create a new Document for the regulation
    reg_doc = Document.new(
      title: "Official Text - #{reg.title}",
      description: "Valid generated PDF for regulation",
      category: 'Regulation',
      status: :approved,
      uploaded_by: user,
      regulation: reg,
      organization: nil
    )
    
    # Generate a valid PDF content using WickedPdf
    pdf_content = WickedPdf.new.pdf_from_string(
      "<h1>#{reg.title}</h1><p>#{reg.full_text['main']}</p>",
      encoding: 'UTF-8'
    )
    
    reg_doc.file.attach(
      io: StringIO.new(pdf_content),
      filename: "regulation_#{reg.id}_valid.pdf",
      content_type: 'application/pdf'
    )
    
    if reg_doc.save
      puts "Successfully attached valid PDF to Regulation #{reg.id} (Document ID: #{reg_doc.id})"
    else
      puts "Failed to attach: #{reg_doc.errors.full_messages.join(', ')}"
    end
  else
    puts "No Regulation found to attach to."
  end

rescue => e
  puts "SCRIPT ERROR: #{e.message}"
  puts e.backtrace.join("\n")
end
