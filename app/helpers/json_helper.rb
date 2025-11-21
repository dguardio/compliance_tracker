module JsonHelper
  def render_json(json)
    content_tag :div, class: 'json-container' do
      json.map do |key, value|
        content_tag :div, class: 'json-entry' do
          content_tag(:strong, "#{key.to_s.titleize}: ", class: 'json-key') +
            if value.is_a?(Hash)
              render_json(value)
            elsif value.is_a?(Array)
              content_tag :div, class: 'json-array' do
                value.map do |item|
                  if item.is_a?(Hash)
                    render_json(item)
                  else
                    content_tag(:div, item.to_s, class: 'json-value')
                  end
                end.join.html_safe
              end
            else
              content_tag(:span, value.to_s, class: 'json-value')
            end
        end
      end.join.html_safe
    end
  end
end
