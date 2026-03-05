module Ai
  # Token-aware Context Management Service
  # Provides utility methods to safely truncate text to fit within
  # specific LLM context windows, using a conservative 1 token ≈ 4 chars estimate.
  class ContextManager
    # Conservative estimate for English text tokenization
    CHARS_PER_TOKEN = 4

    MODEL_LIMITS = {
      'gemini-2.0-flash' => 1_000_000,
      'gemini-2.0-flash-lite' => 1_000_000,
      'gemini-1.5-pro' => 2_000_000,
      'text-embedding-004' => 2_048
    }.freeze

    # Truncates text to fit within a given model's token limit.
    # @param text [String] The text to truncate
    # @param model [String, Symbol] The model identifier for looking up limits
    # @param reserve_tokens [Integer] How many tokens to leave free for prompt/output
    def self.truncate(text, model: 'gemini-2.0-flash', reserve_tokens: 1000)
      return "" if text.blank?

      limit = MODEL_LIMITS[model.to_s] || 128_000
      max_allowed_tokens = [limit - reserve_tokens, 0].max
      max_chars = max_allowed_tokens * CHARS_PER_TOKEN

      text.to_s.truncate(
        max_chars, 
        separator: ' ', 
        omission: "\n\n...[Content truncated to fit Context Window]"
      )
    end

    # Rough estimate of tokens in text
    def self.estimate_tokens(text)
      text.to_s.length / CHARS_PER_TOKEN
    end
  end
end
