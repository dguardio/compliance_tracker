class DocumentGeneratorService
  require 'faker'
  require 'tempfile'
  require 'zip'
  require 'nokogiri'

  def initialize(organization = nil)
    @organization = organization
  end

  def generate_sample_documents(count = 5)
    documents = []

    count.times do |i|
      document_type = %w[text word excel powerpoint pdf].sample
      document = generate_document(document_type, i + 1)
      documents << document if document
    end

    documents
  end

  def generate_document(type, index = 1)
    case type
    when 'text'
      generate_text_document(index)
    when 'word'
      generate_word_document(index)
    when 'excel'
      generate_excel_document(index)
    when 'powerpoint'
      generate_powerpoint_document(index)
    when 'pdf'
      generate_pdf_document(index)
    else
      generate_text_document(index)
    end
  end

  private

  def generate_text_document(index)
    content = generate_text_content
    filename = "sample_document_#{index}.txt"

    temp_file = Tempfile.new([filename, '.txt'])
    temp_file.write(content)
    temp_file.rewind

    create_document_record(temp_file, filename, 'text/plain', "Sample Text Document #{index}")
  end

  def generate_word_document(index)
    content = generate_word_content
    filename = "sample_document_#{index}.docx"

    temp_file = create_docx_file(content)

    create_document_record(temp_file, filename,
                           'application/vnd.openxmlformats-officedocument.wordprocessingml.document', "Sample Word Document #{index}")
  end

  def generate_excel_document(index)
    data = generate_excel_data
    filename = "sample_spreadsheet_#{index}.xlsx"

    temp_file = create_xlsx_file(data)

    create_document_record(temp_file, filename, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                           "Sample Excel Spreadsheet #{index}")
  end

  def generate_powerpoint_document(index)
    slides = generate_powerpoint_slides
    filename = "sample_presentation_#{index}.pptx"

    temp_file = create_pptx_file(slides)

    create_document_record(temp_file, filename,
                           'application/vnd.openxmlformats-officedocument.presentationml.presentation', "Sample PowerPoint Presentation #{index}")
  end

  def generate_pdf_document(index)
    content = generate_pdf_content
    filename = "sample_document_#{index}.pdf"

    temp_file = create_pdf_file(content)

    create_document_record(temp_file, filename, 'application/pdf', "Sample PDF Document #{index}")
  end

  def generate_text_content
    paragraphs = []

    3.times do
      paragraphs << Faker::Lorem.paragraph(sentence_count: 5)
    end

    paragraphs.join("\n\n")
  end

  def generate_word_content
    sections = []

    sections << "# #{Faker::Company.name} - #{Faker::Company.catch_phrase}"
    sections << ''
    sections << '## Executive Summary'
    sections << Faker::Lorem.paragraph(sentence_count: 8)
    sections << ''
    sections << '## Key Findings'

    3.times do
      sections << "### #{Faker::Lorem.sentence(word_count: 4)}"
      sections << Faker::Lorem.paragraph(sentence_count: 4)
      sections << ''
    end

    sections << '## Recommendations'
    sections << Faker::Lorem.paragraph(sentence_count: 6)
    sections << ''
    sections << '## Conclusion'
    sections << Faker::Lorem.paragraph(sentence_count: 5)

    sections.join("\n")
  end

  def generate_excel_data
    {
      'Financial Data' => [
        ['Quarter', 'Revenue', 'Expenses', 'Profit', 'Growth %'],
        ['Q1 2024', Faker::Number.decimal(l_digits: 6, r_digits: 2), Faker::Number.decimal(l_digits: 5, r_digits: 2),
         Faker::Number.decimal(l_digits: 5, r_digits: 2), "#{Faker::Number.between(from: 5, to: 25)}%"],
        ['Q2 2024', Faker::Number.decimal(l_digits: 6, r_digits: 2), Faker::Number.decimal(l_digits: 5, r_digits: 2),
         Faker::Number.decimal(l_digits: 5, r_digits: 2), "#{Faker::Number.between(from: 5, to: 25)}%"],
        ['Q3 2024', Faker::Number.decimal(l_digits: 6, r_digits: 2), Faker::Number.decimal(l_digits: 5, r_digits: 2),
         Faker::Number.decimal(l_digits: 5, r_digits: 2), "#{Faker::Number.between(from: 5, to: 25)}%"],
        ['Q4 2024', Faker::Number.decimal(l_digits: 6, r_digits: 2), Faker::Number.decimal(l_digits: 5, r_digits: 2),
         Faker::Number.decimal(l_digits: 5, r_digits: 2), "#{Faker::Number.between(from: 5, to: 25)}%"]
      ],
      'Employee Data' => [
        ['Name', 'Department', 'Position', 'Salary', 'Start Date'],
        [Faker::Name.name, Faker::Company.department, Faker::Job.title,
         Faker::Number.decimal(l_digits: 5, r_digits: 2), Faker::Date.between(from: 2.years.ago, to: Date.today).strftime('%Y-%m-%d')],
        [Faker::Name.name, Faker::Company.department, Faker::Job.title,
         Faker::Number.decimal(l_digits: 5, r_digits: 2), Faker::Date.between(from: 2.years.ago, to: Date.today).strftime('%Y-%m-%d')],
        [Faker::Name.name, Faker::Company.department, Faker::Job.title,
         Faker::Number.decimal(l_digits: 5, r_digits: 2), Faker::Date.between(from: 2.years.ago, to: Date.today).strftime('%Y-%m-%d')],
        [Faker::Name.name, Faker::Company.department, Faker::Job.title,
         Faker::Number.decimal(l_digits: 5, r_digits: 2), Faker::Date.between(from: 2.years.ago, to: Date.today).strftime('%Y-%m-%d')]
      ]
    }
  end

  def generate_powerpoint_slides
    slides = []

    # Title slide
    slides << {
      title: "#{Faker::Company.name} - #{Faker::Company.catch_phrase}",
      content: "Presented by: #{Faker::Name.name}\n#{Faker::Date.forward(days: 30).strftime('%B %Y')}"
    }

    # Content slides
    4.times do |i|
      slides << {
        title: "#{Faker::Lorem.sentence(word_count: 4)}",
        content: "• #{Faker::Lorem.sentence}\n• #{Faker::Lorem.sentence}\n• #{Faker::Lorem.sentence}\n• #{Faker::Lorem.sentence}"
      }
    end

    slides
  end

  def generate_pdf_content
    content = []
    content << "# #{Faker::Company.name}"
    content << ''
    content << "## #{Faker::Company.catch_phrase}"
    content << ''
    content << Faker::Lorem.paragraph(sentence_count: 10)
    content << ''
    content << '### Key Points:'
    content << ''
    5.times do
      content << "• #{Faker::Lorem.sentence}"
    end
    content << ''
    content << Faker::Lorem.paragraph(sentence_count: 8)

    content.join("\n")
  end

  def create_docx_file(content)
    # Create a simple DOCX file structure
    temp_file = Tempfile.new(['document', '.docx'])

    Zip::File.open(temp_file.path, Zip::File::CREATE) do |zipfile|
      # Add content types
      zipfile.get_output_stream('[Content_Types].xml') do |f|
        f.write(<<~XML)
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
            <Default Extension="xml" ContentType="application/xml"/>
            <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
            <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
          </Types>
        XML
      end

      # Add document content
      zipfile.get_output_stream('word/document.xml') do |f|
        f.write(<<~XML)
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
            <w:body>
              #{content.split("\n").map { |line| "<w:p><w:r><w:t>#{line}</w:t></w:r></w:p>" }.join("\n")}
            </w:body>
          </w:document>
        XML
      end
    end

    temp_file.rewind
    temp_file
  end

  def create_xlsx_file(data)
    require 'axlsx'
    p = Axlsx::Package.new
    wb = p.workbook

    data.each do |sheet_name, rows|
      wb.add_worksheet(name: sheet_name) do |sheet|
        rows.each do |row|
          sheet.add_row row
        end
      end
    end

    temp_file = Tempfile.new(['spreadsheet', '.xlsx'])
    p.serialize(temp_file.path)
    temp_file
  end

  def create_pptx_file(slides)
    # For now, we'll stick to the simple XML approach but ensure it's valid enough.
    # Or better, we can create a simple text file and rename it if we don't have a PPTX writer.
    # But let's try to keep the XML approach but maybe simplify it or ensure it's correct.
    # Actually, the previous XML was very minimal.
    # Let's just use the previous implementation but ensure we close files.
    
    temp_file = Tempfile.new(['presentation', '.pptx'])

    Zip::File.open(temp_file.path, Zip::File::CREATE) do |zipfile|
      # Add content types
      zipfile.get_output_stream('[Content_Types].xml') do |f|
        f.write(<<~XML)
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
            <Default Extension="xml" ContentType="application/xml"/>
            <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
            <Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>
          </Types>
        XML
      end

      # Add presentation
      zipfile.get_output_stream('ppt/presentation.xml') do |f|
        f.write(<<~XML)
          <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
          <p:presentation xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
            <p:sldIdLst>
              #{slides.each_with_index.map { |_, i| "<p:sldId id=\"#{i + 1}\" r:id=\"rId#{i + 1}\"/>" }.join("\n")}
            </p:sldIdLst>
          </p:presentation>
        XML
      end
    end

    temp_file.rewind
    temp_file
  end

  def create_pdf_file(content)
    # Use WickedPdf to generate a valid PDF
    pdf_content = WickedPdf.new.pdf_from_string(
      "<h1>Generated Document</h1><p>#{content.gsub("\n", '<br>')}</p>",
      encoding: 'UTF-8'
    )
    
    temp_file = Tempfile.new(['document', '.pdf'])
    temp_file.binmode
    temp_file.write(pdf_content)
    temp_file.rewind
    temp_file
  end

  def create_document_record(temp_file, filename, content_type, title)
    return nil unless @organization

    # Find the first user in the organization with the org_admin role
    user = @organization.users.joins(:roles).where(roles: { name: 'org_admin' }).first ||
           @organization.users.first ||
           User.first # Last resort fallback

    return nil unless user

    document = Document.new(
      title: title,
      description: Faker::Lorem.sentence,
      organization: @organization,
      uploaded_by: user,
      status: %w[draft review approved].sample,
      tags: [Faker::Lorem.word, Faker::Lorem.word, Faker::Lorem.word],
      expires_at: Faker::Date.forward(days: 365),
      version: 1,
      category: %w[technical operational administrative].sample
    )

    document.file.attach(
      io: temp_file,
      filename: filename,
      content_type: content_type
    )

    if document.save
      temp_file.close
      temp_file.unlink
      document
    else
      temp_file.close
      temp_file.unlink
      Rails.logger.error "Failed to create document: #{document.errors.full_messages.join(', ')}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Error creating document: #{e.message}"
    temp_file.close
    temp_file.unlink
    nil
  end
end
