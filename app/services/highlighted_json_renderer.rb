class HighlightedJsonRenderer
  include ActionView::Helpers::TagHelper
  include ActionView::Context

  def initialize(json, comments)
    @json = json
    @comments = comments.sort_by(&:start_index)
    @current_index = 0
  end

  def render
    render_node(@json)
  end

  private

  def render_node(node)
    content_tag :div, class: 'json-container' do
      if node.is_a?(Hash)
        node.map do |key, value|
          content_tag :div, class: 'json-entry' do
            # Key rendering
            key_text = "#{key.to_s.titleize}: "
            rendered_key = highlight_text(key_text)
            key_tag = content_tag(:strong, rendered_key, class: 'json-key')

            # Value rendering
            rendered_value = if value.is_a?(Hash)
                               render_node(value)
                             elsif value.is_a?(Array)
                               content_tag :div, class: 'json-array' do
                                 value.map do |item|
                                   if item.is_a?(Hash)
                                     render_node(item)
                                   else
                                     content_tag(:div, highlight_text(item.to_s), class: 'json-value')
                                   end
                                 end.join.html_safe
                               end
                             else
                               content_tag(:span, highlight_text(value.to_s), class: 'json-value')
                             end

            key_tag + rendered_value
          end
        end.join.html_safe
      elsif node.is_a?(Array)
        content_tag :div, class: 'json-array' do
          node.map do |item|
            if item.is_a?(Hash)
              render_node(item)
            else
              content_tag(:div, highlight_text(item.to_s), class: 'json-value')
            end
          end.join.html_safe
        end
      else
        content_tag(:span, highlight_text(node.to_s), class: 'json-value')
      end
    end
  end

  def highlight_text(text)
    end_pos = @current_index + text.length
    
    # Find overlapping comments
    overlapping = @comments.select do |c|
      c.start_index < end_pos && c.end_index > @current_index
    end

    result = ""
    
    if overlapping.empty?
      result = text
    else
      # Simple highlighting: just take the first one for now to avoid complex overlap logic
      # or split the text based on boundaries
      
      # We need to process the text character by character or segment by segment
      # Let's use a simple approach: iterate through chars
      
      text.chars.each_with_index do |char, i|
        global_pos = @current_index + i
        
        # Find the most specific comment (shortest range? or just first?)
        # Let's prioritize: Evidence Request > Suggestion > Comment
        active_comment = overlapping.find { |c| global_pos >= c.start_index && global_pos < c.end_index }
        
        if active_comment
          # Optimization: group consecutive chars with same highlight
          # But for now, let's just wrap each char? No, that's too much HTML.
          # We need to build segments.
        end
      end
      
      # Better approach: Scan for boundaries within this text block
      boundaries = [0, text.length]
      overlapping.each do |c|
        start_in_text = [0, c.start_index - @current_index].max
        end_in_text = [text.length, c.end_index - @current_index].min
        boundaries << start_in_text
        boundaries << end_in_text
      end
      boundaries = boundaries.uniq.sort

      boundaries.each_cons(2) do |start_local, end_local|
        segment = text[start_local...end_local]
        next if segment.empty?
        
        mid_point = @current_index + start_local
        
        # Determine active comment for this segment
        # Prioritize: Evidence Request > Suggestion > Comment
        active_comment = overlapping.select { |c| c.start_index <= mid_point && c.end_index > mid_point }
                                    .sort_by { |c| priority_score(c.comment_type) }
                                    .last

        if active_comment
          klass = case active_comment.comment_type
                  when 'suggestion' then 'suggestion-highlight'
                  when 'evidence_request' then 'evidence-request-highlight'
                  else 'comment-highlight'
                  end
          # Use span for all to avoid browser default styling issues with mark
          result += content_tag(:span, segment, class: klass)
        else
          result += segment
        end
      end
    end

    @current_index += text.length
    result.html_safe
  end

  def priority_score(type)
    case type
    when 'evidence_request' then 3
    when 'suggestion' then 2
    else 1
    end
  end
end
