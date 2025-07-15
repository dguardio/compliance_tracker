module DocumentsHelper
  def safe_version_display(version, field = 'version')
    # Try to get the changed value first (for updates)
    changed_value = safe_parse_object_changes(version.object_changes, field)&.last

    # If no change, try to get the current value from object
    current_value = safe_parse_object(version.object, field)

    # Return the best available value or a fallback
    changed_value || current_value || 'Unknown'
  end

  def safe_parse_object_changes(object_changes, field)
    return nil unless object_changes

    if object_changes.is_a?(Hash)
      object_changes[field]
    elsif object_changes.is_a?(String)
      begin
        YAML.load(object_changes)[field]
      rescue StandardError
        nil
      end
    end
  end

  def safe_parse_object(object, field)
    return nil unless object

    if object.is_a?(Hash)
      object[field]
    elsif object.is_a?(String)
      begin
        YAML.load(object)[field]
      rescue StandardError
        nil
      end
    end
  end

  def version_user_name(version)
    return 'Unknown' unless version.whodunnit.present?

    user = User.find_by(id: version.whodunnit)
    user&.full_name || 'Unknown'
  end

  def version_changes_summary(version)
    return 'Created' if version.event == 'create'
    return 'Updated' if version.event == 'update'
    return 'Destroyed' if version.event == 'destroy'

    version.event.titleize
  end

  def safe_text_preview(file, max_size: 5.megabytes)
    return 'File too large to preview' if file.byte_size > max_size

    content = file.download.force_encoding('UTF-8')
    content.length > 1000 ? content[0..1000] + "\n\n... (content truncated)" : content
  rescue StandardError => e
    "Error reading file: #{e.message}"
  end

  def document_preview_data(document)
    return nil unless document.file.attached?

    DocumentPreviewService.new(document).preview_data
  rescue StandardError => e
    Rails.logger.error "Preview data error: #{e.message}"
    {
      type: 'error',
      content: "Preview not available: #{e.message}",
      metadata: {},
      actions: ['download']
    }
  end

  def preview_icon_class(document)
    document.preview_icon_class
  end

  def preview_icon_color(document)
    document.preview_icon_color
  end

  def format_file_size(bytes)
    return '0 B' if bytes.nil? || bytes == 0

    units = %w[B KB MB GB TB]
    size = bytes.to_f
    unit_index = 0

    while size >= 1024 && unit_index < units.length - 1
      size /= 1024
      unit_index += 1
    end

    "#{size.round(1)} #{units[unit_index]}"
  end

  def office_online_url(document)
    return nil unless document.file.attached?

    base_url = request.base_url
    file_url = rails_blob_path(document.file)
    "https://view.officeapps.live.com/op/embed.aspx?src=#{CGI.escape(base_url + file_url)}"
  end

  def preview_metadata_summary(metadata)
    return '' if metadata.blank?

    parts = []
    parts << "#{metadata[:pages]} pages" if metadata[:pages]
    parts << "#{metadata[:sheets]} sheets" if metadata[:sheets]
    parts << "#{metadata[:slides]} slides" if metadata[:slides]
    parts << "#{metadata[:lines]} lines" if metadata[:lines]
    parts << "#{metadata[:words]} words" if metadata[:words]
    parts << "#{metadata[:characters]} chars" if metadata[:characters]

    parts.join(' • ')
  end
end
