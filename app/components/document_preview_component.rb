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
    content_tag(:div, class: 'pdf-preview') do
      if pdfjs_viewer_url.present?
        content_tag(:iframe, '', src: pdfjs_viewer_url, class: 'pdf-viewer', frameborder: '0')
      else
        content_tag(:p, 'PDF viewer not available', class: 'text-gray-500')
      end
    end
  end

  def render_text_preview
    content_tag(:div, class: 'text-preview') do
      content_tag(:pre, preview_content)
    end
  end

  def render_word_preview
    content_tag(:div, class: 'word-preview') do
      content_tag(:div, class: 'text-preview') do
        content_tag(:pre, preview_content)
      end
    end
  end

  def render_excel_preview
    content_tag(:div, class: 'excel-preview') do
      if preview_content.is_a?(Hash) && preview_content[:sheets].present?
        preview_content[:sheets].map do |sheet|
          content_tag(:div, class: 'mb-6') do
            content_tag(:h4, "Sheet: #{sheet[:name]}", class: 'text-lg font-semibold mb-2') +
              content_tag(:table, class: 'excel-table') do
                if sheet[:rows].present?
                  header_row = sheet[:rows].first
                  data_rows = sheet[:rows][1..50] # Limit to 50 rows for preview

                  content_tag(:thead) do
                    content_tag(:tr) do
                      header_row.map { |cell| content_tag(:th, cell.to_s) }.join.html_safe
                    end
                  end +
                    content_tag(:tbody) do
                      data_rows.map do |row|
                        content_tag(:tr) do
                          row.map { |cell| content_tag(:td, cell.to_s) }.join.html_safe
                        end
                      end.join.html_safe
                    end
                end
              end
          end
        end.join.html_safe
      else
        content_tag(:p, 'Unable to preview Excel content', class: 'text-gray-500')
      end
    end
  end

  def render_powerpoint_preview
    content_tag(:div, class: 'powerpoint-preview') do
      if preview_content.is_a?(Hash) && preview_content[:slides].present?
        preview_content[:slides].map do |slide|
          content_tag(:div, class: 'slide-item') do
            content_tag(:div, class: 'slide-title') do
              "Slide #{slide[:slide_number]}"
            end +
              content_tag(:div, class: 'slide-content') do
                slide[:content] || slide[:text] || 'No content available'
              end
          end
        end.join.html_safe
      else
        content_tag(:p, 'Unable to preview PowerPoint content', class: 'text-gray-500')
      end
    end
  end

  def render_generic_preview
    content_tag(:div, class: 'generic-preview') do
      content_tag(:p, 'Preview not available for this file type', class: 'text-gray-500')
    end
  end
end
