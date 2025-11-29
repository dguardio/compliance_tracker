class DocumentPreviewComponent < ViewComponent::Base
  def initialize(document:, current_user:)
    @document = document
    @current_user = current_user
    @preview_data = document.preview_data
  end

  def render?
    @document.previewable? && @preview_data.present?
  end

  def preview_type
    @preview_data&.dig(:type) || 'unknown'
  end

  def preview_content
    @preview_data&.dig(:content)
  end

  def preview_metadata
    @preview_data&.dig(:metadata) || {}
  end

  def preview_actions
    @preview_data&.dig(:actions) || ['download']
  end

  def pdfjs_viewer_url
    return nil unless @document.pdf_previewable?

    begin
      Rails.application.routes.url_helpers.rails_blob_url(@document.file, disposition: :inline)
    rescue ActionController::UrlGenerationError => e
      Rails.logger.error "URL generation error for PDF: #{e.message}"
      nil
    end
  end

  def download_url
    Rails.application.routes.url_helpers.rails_blob_url(@document.file, disposition: :attachment)
  rescue ActionController::UrlGenerationError => e
    Rails.logger.error "URL generation error for download: #{e.message}"
    '#'
  end

  def image_url
    return nil unless @document.image_previewable?

    begin
      Rails.application.routes.url_helpers.rails_blob_url(@document.file, disposition: :inline)
    rescue ActionController::UrlGenerationError => e
      Rails.logger.error "URL generation error for image: #{e.message}"
      nil
    end
  end

  def office_online_url
    # Microsoft Office Online viewer URL

    file_url = Rails.application.routes.url_helpers.rails_blob_url(@document.file, disposition: :inline)
    "https://view.officeapps.live.com/op/embed.aspx?src=#{CGI.escape(file_url)}"
  rescue ActionController::UrlGenerationError => e
    Rails.logger.error "URL generation error for Office Online: #{e.message}"
    '#'
  end

  private

  def can_preview?
    @document.previewable?
  end

  def render_preview_action(action)
    case action
    when 'download'
      link_to download_url,
              class: 'inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500' do
        content_tag(:i, '', class: 'fas fa-download mr-2') + 'Download'
      end
    when 'open_new_tab'
      link_to download_url, target: '_blank',
                            class: 'inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500' do
        content_tag(:i, '', class: 'fas fa-external-link-alt mr-2') + 'Open'
      end
    when 'pdfjs_viewer'
      link_to '#', onclick: "openPdfViewer('#{pdfjs_viewer_url}')",
                   class: 'inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500' do
        content_tag(:i, '', class: 'fas fa-eye mr-2') + 'View PDF'
      end
    when 'embed_viewer'
      link_to '#', onclick: "embedViewer('#{office_online_url}')",
                   class: 'inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500' do
        content_tag(:i, '', class: 'fas fa-desktop mr-2') + 'Embed'
      end
    when 'office_online'
      link_to office_online_url, target: '_blank',
                                 class: 'inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm leading-4 font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500' do
        content_tag(:i, '', class: 'fas fa-external-link-alt mr-2') + 'Office Online'
      end
    end
  end

  def render_image_preview
    content_tag(:div, class: 'image-preview') do
      if image_url.present?
        image_tag image_url, class: 'max-w-full h-auto rounded-lg shadow-sm', alt: @document.title
      else
        content_tag(:p, 'Image preview not available', class: 'text-gray-500')
      end
    end
  end

  def render_pdf_preview
    content_tag(:div, class: 'pdf-preview', style: 'height: 600px;') do
      if pdfjs_viewer_url.present?
        # Use object tag for better PDF embedding support
        content_tag(:object, data: pdfjs_viewer_url, type: 'application/pdf', width: '100%', height: '100%') do
          content_tag(:p, class: 'p-4 text-center') do
            ("Your browser does not support PDFs. " +
            link_to("Download the PDF", download_url, class: "text-indigo-600 hover:text-indigo-900 underline") +
            " to view it.").html_safe
          end
        end
      else
        content_tag(:p, 'PDF viewer not available', class: 'text-gray-500')
      end
    end
  end

  def render_text_preview
    if preview_content.present?
      content_tag(:div, class: 'text-preview') do
        content_tag(:pre, preview_content)
      end
    else
      render_empty_state("No text content could be extracted.")
    end
  end

  def render_word_preview
    if @document.file.previewable?
      render_active_storage_preview
    else
      render_extracted_text_preview("Word")
    end
  end

  def render_excel_preview
    if @document.file.previewable?
      render_active_storage_preview
    else
      render_extracted_excel_preview
    end
  end

  def render_powerpoint_preview
    if @document.file.previewable?
      render_active_storage_preview
    else
      render_extracted_powerpoint_preview
    end
  end

  private

  def render_active_storage_preview
    content_tag(:div, class: 'active-storage-preview text-center') do
      image_tag(@document.file.preview(resize_to_limit: [1024, 1024]), class: 'max-w-full h-auto shadow-lg rounded-lg mx-auto')
    end
  rescue StandardError => e
    Rails.logger.error "Preview generation failed: #{e.message}"
    # Fallback to text extraction if preview generation fails
    case @document.document_type_category
    when 'word' then render_extracted_text_preview("Word")
    when 'excel' then render_extracted_excel_preview
    when 'powerpoint' then render_extracted_powerpoint_preview
    else render_empty_state("Preview generation failed.")
    end
  end

  def render_extracted_text_preview(type)
    content_tag(:div, class: 'word-preview') do
      if Rails.env.development?
        content_tag(:div, class: 'bg-yellow-50 p-4 mb-4 rounded-md') do
          content_tag(:p, "Visual preview not available. Showing extracted text:", class: 'text-sm text-yellow-700')
        end
      end +
      (preview_content.present? ? 
        content_tag(:div, class: 'text-preview') { content_tag(:pre, preview_content) } :
        render_empty_state("No text content could be extracted from this #{type} document."))
    end
  end

  def render_extracted_excel_preview
    content_tag(:div, class: 'excel-preview') do
      if Rails.env.development?
        content_tag(:div, class: 'bg-yellow-50 p-4 mb-4 rounded-md') do
          content_tag(:p, "Visual preview not available. Showing extracted data:", class: 'text-sm text-yellow-700')
        end
      end +
      if preview_content.is_a?(Hash) && preview_content[:sheets].present?
        preview_content[:sheets].map do |sheet|
          content_tag(:div, class: 'mb-6') do
            content_tag(:h4, "Sheet: #{sheet[:name]}", class: 'text-lg font-semibold mb-2') +
              content_tag(:div, class: 'overflow-x-auto') do
                content_tag(:table, class: 'excel-table min-w-full divide-y divide-gray-200') do
                  if sheet[:rows].present?
                    header_row = sheet[:rows].first
                    data_rows = sheet[:rows][1..50] # Limit to 50 rows for preview

                    content_tag(:thead, class: 'bg-gray-50') do
                      content_tag(:tr) do
                        header_row.map { |cell| content_tag(:th, cell.to_s, class: 'px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider') }.join.html_safe
                      end
                    end +
                      content_tag(:tbody, class: 'bg-white divide-y divide-gray-200') do
                        data_rows.map do |row|
                          content_tag(:tr) do
                            row.map { |cell| content_tag(:td, cell.to_s, class: 'px-6 py-4 whitespace-nowrap text-sm text-gray-500') }.join.html_safe
                          end
                        end.join.html_safe
                      end
                  end
                end
              end
          end
        end.join.html_safe
      else
        render_empty_state("No data could be extracted from this Excel file.")
      end
    end
  end

  def render_extracted_powerpoint_preview
    content_tag(:div, class: 'powerpoint-preview') do
      if Rails.env.development?
        content_tag(:div, class: 'bg-yellow-50 p-4 mb-4 rounded-md') do
          content_tag(:p, "Visual preview not available. Showing extracted slides:", class: 'text-sm text-yellow-700')
        end
      end +
      if preview_content.is_a?(Hash) && preview_content[:slides].present?
        preview_content[:slides].map do |slide|
          content_tag(:div, class: 'slide-item mb-4 p-4 border rounded shadow-sm') do
            content_tag(:div, class: 'slide-title font-bold mb-2') do
              "Slide #{slide[:slide_number]}"
            end +
              content_tag(:div, class: 'slide-content text-gray-700') do
                simple_format(slide[:content] || slide[:text] || 'No content available')
              end
          end
        end.join.html_safe
      else
        render_empty_state("No content could be extracted from this PowerPoint presentation.")
      end
    end
  end

  def render_generic_preview
    render_empty_state("Preview not available for this file type.")
  end
  
  def render_empty_state(message)
    content_tag(:div, class: 'text-center py-12 bg-gray-50 rounded-lg border-2 border-dashed border-gray-300') do
      content_tag(:i, '', class: 'fas fa-file-alt text-4xl text-gray-400 mb-3') +
      content_tag(:p, message, class: 'text-gray-500') +
      link_to("Download File", download_url, class: "mt-4 inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500")
    end
  end
end
