module Ai
  # Shared JSON extraction utility for LLM responses.
  #
  # Use this as a FALLBACK when RubyLLM::Schema is not applicable
  # (e.g., tool-based agentic flows, legacy services during migration).
  #
  # For NEW structured output needs, prefer:
  #   Ai::Client.chat_with_schema(prompt, SchemaClass)
  #
  # Usage:
  #   data = Ai::ResponseParser.json(response.content)
  #   items = Ai::ResponseParser.json_array(response.content)
  #
  module ResponseParser
    extend self

    # Parse JSON from an LLM response string.
    # Handles markdown code blocks, partial JSON, and whitespace.
    # Returns Hash, Array, or nil on failure.
    #
    def json(content)
      return nil if content.blank?

      cleaned = extract_json_block(content)
      parsed  = JSON.parse(cleaned)

      # Symbolize keys if Hash
      if parsed.is_a?(Hash)
        deep_symbolize(parsed)
      elsif parsed.is_a?(Array)
        parsed.map { |item| item.is_a?(Hash) ? deep_symbolize(item) : item }
      else
        parsed
      end
    rescue JSON::ParserError => e
      Rails.logger.warn "[Ai::ResponseParser] JSON parse failed: #{e.message}"
      Rails.logger.debug "[Ai::ResponseParser] Raw content: #{content.truncate(500)}"
      nil
    end

    # Parse JSON and always return an Array.
    # If the response is a Hash with a single array-valued key, unwrap it.
    # Returns [] on failure.
    #
    def json_array(content)
      result = json(content)

      case result
      when Array
        result
      when Hash
        # Auto-unwrap: { requirements: [...] } → [...]
        # Finds the first key whose value is an Array
        array_val = result.values.find { |v| v.is_a?(Array) }
        array_val || [result]
      else
        []
      end
    end

    private

    # Extract JSON from markdown code blocks or raw content
    def extract_json_block(content)
      # Try ```json ... ``` block first
      if (match = content.match(/```(?:json)?\s*\n?(.*?)\n?\s*```/m))
        return match[1].strip
      end

      # Try to find raw JSON (object or array)
      stripped = content.strip

      # If it starts with { or [, treat as raw JSON
      if stripped.start_with?('{') || stripped.start_with?('[')
        return stripped
      end

      # Last resort: find the first { or [ and take everything from there to the matching close
      if (start_idx = stripped.index(/[\[{]/))
        return stripped[start_idx..]
      end

      stripped
    end

    def deep_symbolize(obj)
      case obj
      when Hash
        obj.each_with_object({}) do |(key, val), result|
          sym_key = key.respond_to?(:to_sym) ? key.to_sym : key
          result[sym_key] = deep_symbolize(val)
        end
      when Array
        obj.map { |item| deep_symbolize(item) }
      else
        obj
      end
    end
  end
end
