module Ai
  # Central wrapper for all LLM interactions in the application.
  #
  # Replaces direct RubyLLM.chat.ask() calls with a standardized interface
  # that provides: automatic AgentTrace recording, ModelRouter integration,
  # token tracking, cost estimation, and centralized error handling.
  #
  # Usage:
  #   Ai::Client.chat("What is GDPR?", task_type: :factual, agent_name: "SearchExpander")
  #   Ai::Client.chat_with_schema("Extract metadata...", Ai::Schemas::MetadataSchema, agent_name: "MetadataExtractor")
  #   Ai::Client.agent_chat("Research org...", tools: [Tool1, Tool2], instructions: "...", agent_name: "ResearchAgent")
  #   Ai::Client.stream("Generate report...", agent_name: "ReportWriter") { |chunk| ... }
  #   Ai::Client.embed("some text")
  #   Ai::Client.embed(["text1", "text2"])
  #
  class Client
    # Static model lookup — callers pass task_type explicitly.
    # Maps directly to ModelRouter::MODELS without an extra LLM classification call.
    MODEL_MAP = {
      classifier: 'gemini-2.0-flash',
      factual:    'gemini-2.0-flash',
      analysis:   'gemini-2.0-flash',
      drafting:   'gemini-2.0-flash',
      coding:     'gemini-2.0-flash'
    }.freeze

    # Temperature defaults per task type
    TEMPERATURE_MAP = {
      classifier: 0.0,
      factual:    0.1,
      analysis:   0.3,
      drafting:   0.7,
      coding:     0.2
    }.freeze

    MAX_RETRIES = 1

    # ─── Pattern 1: Simple one-shot chat ────────────────────────────
    # Replaces: RubyLLM.chat.ask(prompt) and RubyLLM.chat(model: X).ask(prompt)
    #
    def self.chat(prompt, task_type: :factual, agent_name: "Unknown", model: nil, temperature: nil)
      model       ||= MODEL_MAP[task_type] || MODEL_MAP[:factual]
      temperature ||= TEMPERATURE_MAP[task_type]

      trace = start_trace(agent_name: agent_name, action: "chat", input: prompt, model: model)
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      response = with_retry do
        chat_instance = RubyLLM.chat(model: model)
        chat_instance = chat_instance.with_temperature(temperature) if temperature
        chat_instance.ask(prompt)
      end

      complete_trace(trace, response, started_at, model)
      response

    rescue => e
      fail_trace(trace, e, started_at)
      Rails.logger.error "[Ai::Client] chat failed (#{agent_name}): #{e.message}"
      raise
    end

    # ─── Pattern 2: Structured output via RubyLLM::Schema ──────────
    # Replaces: RubyLLM.chat.ask(prompt) + manual JSON.parse
    # Returns response with guaranteed schema-compliant content
    #
    def self.chat_with_schema(prompt, schema_class, task_type: :analysis, agent_name: "Unknown", model: nil, temperature: nil)
      model       ||= MODEL_MAP[task_type] || MODEL_MAP[:factual]
      temperature ||= TEMPERATURE_MAP[task_type] || 0.1

      trace = start_trace(agent_name: agent_name, action: "chat_with_schema", input: prompt, model: model)
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      response = with_retry do
        chat_instance = RubyLLM.chat(model: model)
        chat_instance = chat_instance.with_temperature(temperature)
        chat_instance.with_schema(schema_class).ask(prompt)
      end

      complete_trace(trace, response, started_at, model)
      response

    rescue => e
      fail_trace(trace, e, started_at)
      Rails.logger.error "[Ai::Client] chat_with_schema failed (#{agent_name}): #{e.message}"
      raise
    end

    # ─── Pattern 3: Agentic chat with tools ─────────────────────────
    # Replaces: RubyLLM.chat(model:).with_tools(T1, T2).with_instructions(str).ask(prompt)
    #
    def self.agent_chat(prompt, tools:, instructions:, agent_name:, model: nil, run_id: nil)
      model ||= MODEL_MAP[:analysis]
      run_id ||= SecureRandom.uuid

      trace = start_trace(agent_name: agent_name, action: "agent_chat", input: prompt, model: model, run_id: run_id)
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      chat_instance = RubyLLM.chat(model: model)
                             .with_tools(*tools)
                             .with_instructions(instructions)

      # Wire tool call tracing
      chat_instance.on_tool_call do |tool_call|
        Ai::AgentTrace.start_trace(
          run_id: run_id,
          agent_name: "#{agent_name}::Tool",
          action: tool_call.name,
          input: { arguments: tool_call.arguments },
          parent_id: trace&.id
        )
        Rails.logger.info "[Ai::Client] Tool call: #{tool_call.name}(#{tool_call.arguments})"
      end

      response = chat_instance.ask(prompt)

      complete_trace(trace, response, started_at, model)
      response

    rescue => e
      fail_trace(trace, e, started_at)
      Rails.logger.error "[Ai::Client] agent_chat failed (#{agent_name}): #{e.message}"
      raise
    end

    # ─── Pattern 4: Streaming chat ──────────────────────────────────
    # Replaces: RubyLLM.chat.ask(prompt) { |chunk| ... }
    #
    def self.stream(prompt, task_type: :drafting, agent_name: "Unknown", model: nil, temperature: nil, &block)
      model       ||= MODEL_MAP[task_type] || MODEL_MAP[:factual]
      temperature ||= TEMPERATURE_MAP[task_type]

      trace = start_trace(agent_name: agent_name, action: "stream", input: prompt, model: model)
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      chat_instance = RubyLLM.chat(model: model)
      chat_instance = chat_instance.with_temperature(temperature) if temperature

      response = chat_instance.ask(prompt, &block)

      complete_trace(trace, response, started_at, model)
      response

    rescue => e
      fail_trace(trace, e, started_at)
      Rails.logger.error "[Ai::Client] stream failed (#{agent_name}): #{e.message}"
      raise
    end

    # ─── Pattern 5: Embeddings ──────────────────────────────────────
    # Replaces: RubyLLM.embed(text) — supports single text or array (batch)
    #
    def self.embed(text_or_array, agent_name: "EmbeddingService")
      return nil if text_or_array.blank?

      trace = start_trace(
        agent_name: agent_name,
        action: "embed",
        input: text_or_array.is_a?(Array) ? "#{text_or_array.length} texts" : text_or_array.to_s.truncate(200),
        model: 'text-embedding-004'
      )
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      response = RubyLLM.embed(text_or_array)

      # For single text: vectors is float array
      # For array: vectors is array of float arrays
      vectors = response.vectors
      tokens  = response.input_tokens

      if trace
        trace.complete!(
          output: "#{vectors.is_a?(Array) && vectors.first.is_a?(Array) ? vectors.length : 1} embedding(s) generated",
          metadata: {
            model: response.model,
            input_tokens: tokens,
            dimensions: vectors.is_a?(Array) && vectors.first.is_a?(Array) ? vectors.first.length : vectors.length,
            latency_ms: ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
          }
        )
      end

      # Normalize: always return the vector(s) in a consistent format
      if text_or_array.is_a?(Array)
        vectors # array of arrays
      else
        # Single text — return flat array
        vectors.first.is_a?(Array) ? vectors.first : vectors
      end

    rescue => e
      fail_trace(trace, e, started_at) if trace
      Rails.logger.error "[Ai::Client] embed failed (#{agent_name}): #{e.message}"
      nil
    end

    # ─── Model info helper ──────────────────────────────────────────
    def self.model_for(task_type)
      MODEL_MAP[task_type.to_sym] || MODEL_MAP[:factual]
    end

    private

    # ─── Trace helpers ──────────────────────────────────────────────

    def self.start_trace(agent_name:, action:, input:, model:, run_id: nil)
      Ai::AgentTrace.start_trace(
        run_id: run_id || SecureRandom.uuid,
        agent_name: agent_name,
        action: action,
        input: { prompt: input.to_s.truncate(500), model: model }
      )
    rescue => e
      Rails.logger.warn "[Ai::Client] Failed to start trace: #{e.message}"
      nil
    end

    def self.complete_trace(trace, response, started_at, model)
      return unless trace

      latency_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
      input_tokens  = response.respond_to?(:input_tokens)  ? response.input_tokens  : nil
      output_tokens = response.respond_to?(:output_tokens) ? response.output_tokens : nil

      # Cost estimation
      estimated_cost = estimate_cost(model, input_tokens, output_tokens)

      trace.complete!(
        output: response.respond_to?(:content) ? response.content.to_s.truncate(1000) : "OK",
        metadata: {
          model: model,
          input_tokens: input_tokens,
          output_tokens: output_tokens,
          estimated_cost_usd: estimated_cost,
          latency_ms: latency_ms
        }
      )
    rescue => e
      Rails.logger.warn "[Ai::Client] Failed to complete trace: #{e.message}"
    end

    def self.fail_trace(trace, error, started_at)
      return unless trace

      latency_ms = started_at ? ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round : nil
      trace.fail!(
        error_message: error.message,
        metadata: { latency_ms: latency_ms, error_class: error.class.name }
      )
    rescue => e
      Rails.logger.warn "[Ai::Client] Failed to record trace failure: #{e.message}"
    end

    def self.estimate_cost(model_id, input_tokens, output_tokens)
      return nil unless input_tokens && output_tokens

      model_info = RubyLLM.models.find(model_id)
      return nil unless model_info&.input_price_per_million && model_info&.output_price_per_million

      input_cost  = input_tokens.to_f  * model_info.input_price_per_million  / 1_000_000
      output_cost = output_tokens.to_f * model_info.output_price_per_million / 1_000_000
      (input_cost + output_cost).round(8)
    rescue => e
      Rails.logger.debug "[Ai::Client] Cost estimation failed: #{e.message}"
      nil
    end

    # ─── Retry logic ────────────────────────────────────────────────

    def self.with_retry(retries: MAX_RETRIES, &block)
      attempts = 0
      begin
        yield
      rescue Faraday::ServerError, Faraday::TimeoutError, Faraday::ConnectionFailed => e
        attempts += 1
        if attempts <= retries
          Rails.logger.warn "[Ai::Client] Retrying (#{attempts}/#{retries}) after: #{e.message}"
          sleep(attempts * 0.5)
          retry
        end
        raise
      end
    end
  end
end
