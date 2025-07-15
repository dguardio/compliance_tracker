class DocumentPreviewService
  require 'roo'
  require 'zip'
  require 'docx'
  require 'creek'
  require 'nokogiri'

  def initialize(document)
    @document = document
    @file = document.file
  end

  def preview_data
    return nil unless @file.attached?

    case @document.document_type_category
    when 'image'
      image_preview_data
    when 'text'
      text_preview_data
    when 'pdf'
      pdf_preview_data
    when 'word'
      word_preview_data
    when 'excel'
      excel_preview_data
    when 'powerpoint'
      powerpoint_preview_data
    else
      generic_preview_data
    end
  rescue StandardError => e
    Rails.logger.error "Document preview error: #{e.message}"
    error_preview_data(e.message)
  end

  private

  def image_preview_data
    {
      type: 'image',
      content: nil,
      metadata: {
        dimensions: image_dimensions,
        format: @file.content_type,
        size: @file.byte_size
      },
      actions: %w[view_full open_new_tab]
    }
  end

  def text_preview_data
    content = safe_text_content
    {
      type: 'text',
      content: content,
      metadata: {
        lines: content.lines.count,
        characters: content.length,
        encoding: 'UTF-8'
      },
      actions: ['open_new_tab']
    }
  end

  def pdf_preview_data
    {
      type: 'pdf',
      content: nil,
      metadata: {
        pages: pdf_page_count,
        size: @file.byte_size,
        format: 'PDF'
      },
      actions: %w[open_new_tab embed_viewer]
    }
  end

  def word_preview_data
    content = extract_word_content
    {
      type: 'word',
      content: content,
      metadata: {
        paragraphs: content.split(/\n\s*\n/).count,
        words: content.split(/\s+/).count,
        characters: content.length
      },
      actions: %w[office_online open_new_tab]
    }
  end

  def excel_preview_data
    content = extract_excel_content
    {
      type: 'excel',
      content: content,
      metadata: {
        sheets: content[:sheets]&.count || 0,
        rows: content[:total_rows] || 0,
        columns: content[:total_columns] || 0
      },
      actions: %w[office_online open_new_tab]
    }
  end

  def powerpoint_preview_data
    content = extract_powerpoint_content
    {
      type: 'powerpoint',
      content: content,
      metadata: {
        slides: content[:slides]&.count || 0,
        notes: content[:notes]&.count || 0
      },
      actions: %w[office_online open_new_tab]
    }
  end

  def generic_preview_data
    {
      type: 'generic',
      content: nil,
      metadata: {
        filename: @file.filename,
        size: @file.byte_size,
        content_type: @file.content_type
      },
      actions: ['open_new_tab']
    }
  end

  def error_preview_data(error_message)
    {
      type: 'error',
      content: "Preview not available: #{error_message}",
      metadata: {},
      actions: ['open_new_tab']
    }
  end

  # Content extraction methods

  def safe_text_content
    return '' if @file.byte_size > 5.megabytes

    content = @file.download.force_encoding('UTF-8')
    content.length > 1000 ? content[0..1000] + "\n\n... (content truncated)" : content
  rescue StandardError => e
    "Error reading file: #{e.message}"
  end

  def extract_word_content
    return '' unless @file.content_type.include?('word')

    if @file.content_type.include?('openxmlformats')
      extract_docx_content
    else
      extract_doc_content
    end
  rescue StandardError => e
    "Error extracting Word content: #{e.message}"
  end

  def extract_docx_content
    require 'docx'

    temp_file = download_to_temp
    doc = Docx::Document.open(temp_file.path)
    content = doc.paragraphs.map(&:text).join("\n")

    # Clean up
    temp_file.close
    temp_file.unlink

    content.length > 1000 ? content[0..1000] + "\n\n... (content truncated)" : content
  rescue StandardError => e
    "Error reading DOCX: #{e.message}"
  end

  def extract_doc_content
    # For older .doc files, we'll return a message since they're harder to parse
    'Content preview not available for older .doc format. Please use the online viewer.'
  end

  def extract_excel_content
    return { sheets: [], total_rows: 0, total_columns: 0 } unless @file.content_type.include?('excel')

    if @file.content_type.include?('openxmlformats')
      extract_xlsx_content
    else
      extract_xls_content
    end
  rescue StandardError => e
    { error: "Error extracting Excel content: #{e.message}" }
  end

  def extract_xlsx_content
    temp_file = download_to_temp

    # Try Creek first (better for large files)
    begin
      workbook = Creek::Book.new(temp_file.path)
      sheets_data = workbook.sheets.map do |sheet|
        rows = sheet.rows.take(50) # Limit to first 50 rows for preview
        {
          name: sheet.name,
          rows: rows.map { |row| row.values.compact },
          row_count: sheet.rows.count
        }
      end

      total_rows = sheets_data.sum { |sheet| sheet[:row_count] }
      total_columns = sheets_data.map { |sheet| sheet[:rows].map(&:length).max || 0 }.max || 0

      {
        sheets: sheets_data,
        total_rows: total_rows,
        total_columns: total_columns
      }
    rescue StandardError => e
      # Fallback to Roo
      begin
        workbook = Roo::Spreadsheet.open(temp_file.path)
        sheets_data = workbook.sheets.map do |sheet_name|
          workbook.default_sheet = sheet_name
          rows = workbook.to_a.take(50) # Limit to first 50 rows
          {
            name: sheet_name,
            rows: rows,
            row_count: workbook.last_row || 0
          }
        end

        total_rows = sheets_data.sum { |sheet| sheet[:row_count] }
        total_columns = sheets_data.map { |sheet| sheet[:rows].map(&:length).max || 0 }.max || 0

        {
          sheets: sheets_data,
          total_rows: total_rows,
          total_columns: total_columns
        }
      rescue StandardError => e2
        { error: "Error reading Excel file: #{e2.message}" }
      end
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def extract_xls_content
    temp_file = download_to_temp

    begin
      workbook = Roo::Spreadsheet.open(temp_file.path)
      sheets_data = workbook.sheets.map do |sheet_name|
        workbook.default_sheet = sheet_name
        rows = workbook.to_a.take(50) # Limit to first 50 rows
        {
          name: sheet_name,
          rows: rows,
          row_count: workbook.last_row || 0
        }
      end

      total_rows = sheets_data.sum { |sheet| sheet[:row_count] }
      total_columns = sheets_data.map { |sheet| sheet[:rows].map(&:length).max || 0 }.max || 0

      {
        sheets: sheets_data,
        total_rows: total_rows,
        total_columns: total_columns
      }
    rescue StandardError => e
      { error: "Error reading XLS file: #{e.message}" }
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def extract_powerpoint_content
    return { slides: [], notes: [] } unless @file.content_type.include?('powerpoint')

    if @file.content_type.include?('openxmlformats')
      extract_pptx_content
    else
      extract_ppt_content
    end
  rescue StandardError => e
    { error: "Error extracting PowerPoint content: #{e.message}" }
  end

  def extract_pptx_content
    temp_file = download_to_temp

    begin
      Zip::File.open(temp_file.path) do |zip_file|
        slides = []
        notes = []

        # Extract slide content
        zip_file.glob('ppt/slides/slide*.xml').each do |entry|
          doc = Nokogiri::XML(entry.get_input_stream.read)
          text_elements = doc.xpath('//a:t') # Text elements in PowerPoint
          slide_text = text_elements.map(&:text).join(' ')
          slides << { text: slide_text } if slide_text.present?
        end

        # Extract notes content
        zip_file.glob('ppt/notesSlides/notesSlide*.xml').each do |entry|
          doc = Nokogiri::XML(entry.get_input_stream.read)
          text_elements = doc.xpath('//a:t')
          note_text = text_elements.map(&:text).join(' ')
          notes << { text: note_text } if note_text.present?
        end

        return {
          slides: slides,
          notes: notes
        }
      end
    rescue StandardError => e
      { error: "Error reading PPTX file: #{e.message}" }
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def extract_ppt_content
    # For older .ppt files, return a message
    { error: 'Content preview not available for older .ppt format. Please use the online viewer.' }
  end

  def pdf_page_count
    return 0 unless @file.content_type == 'application/pdf'

    temp_file = download_to_temp

    begin
      require 'pdf-reader'
      reader = PDF::Reader.new(temp_file.path)
      reader.page_count
    rescue StandardError => e
      Rails.logger.error "Error reading PDF page count: #{e.message}"
      0
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def image_dimensions
    return nil unless @document.image_previewable?

    temp_file = download_to_temp

    begin
      require 'mini_magick'
      image = MiniMagick::Image.open(temp_file.path)
      { width: image.width, height: image.height }
    rescue StandardError => e
      Rails.logger.error "Error reading image dimensions: #{e.message}"
      nil
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  def download_to_temp
    require 'tempfile'
    temp_file = Tempfile.new(['document_preview', File.extname(@file.filename.to_s)])
    temp_file.binmode
    temp_file.write(@file.download)
    temp_file.rewind
    temp_file
  end
end
