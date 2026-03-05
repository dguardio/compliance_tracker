class QuestionnaireAutofillService
  def initialize(organization)
    @organization = organization
  end

  # Process an uploaded questionnaire file
  def process(upload)
    # Parse the file (CSV support)
    questions = parse_file(upload)
    return if questions.empty?

    questions.each do |question_text|
      # Find best matching policy using keyword search
      best_match = find_best_policy_match(question_text)

      answer = generate_answer(question_text, best_match)

      QuestionnaireAnswer.create!(
        questionnaire_upload: upload,
        question_text: question_text,
        ai_answer: answer[:text],
        confidence: answer[:confidence],
        source_policy: best_match[:policy],
        status: :pending
      )
    end

    upload.update!(
      status: :ready,
      response_count: upload.questionnaire_answers.count
    )
  end

  # Export completed questionnaire as CSV
  def export_csv(upload)
    require 'csv'

    CSV.generate(headers: true) do |csv|
      csv << ['Question', 'Answer', 'Confidence', 'Source Policy', 'Status']

      upload.questionnaire_answers.order(:id).each do |answer|
        csv << [
          answer.question_text,
          answer.approved_answer.presence || answer.ai_answer,
          "#{answer.confidence}%",
          answer.source_policy&.title || 'N/A',
          answer.status
        ]
      end
    end
  end

  private

  def parse_file(upload)
    return [] unless upload.file.attached?

    content = upload.file.download
    questions = []

    if upload.filename.end_with?('.csv')
      require 'csv'
      csv = CSV.parse(content, headers: true)
      # Look for a column with 'question' in the header
      question_col = csv.headers.find { |h| h&.downcase&.include?('question') } || csv.headers.first
      csv.each { |row| questions << row[question_col] if row[question_col].present? }
    else
      # Plain text — treat each line as a question
      content.split("\n").each { |line| questions << line.strip if line.strip.present? }
    end

    questions
  end

  def find_best_policy_match(question_text)
    # Try embedding-based semantic search first
    question_embedding = Ai::Client.embed(question_text, agent_name: "QuestionnaireAutofill")

    if question_embedding.present?
      # Use pgvector nearest neighbor search on policies
      # Fall back to keyword search if no policies have embeddings
      best_policy = find_by_embedding(question_embedding)
      if best_policy
        return { policy: best_policy[:policy], score: best_policy[:score], words_matched: 0, method: :embedding }
      end
    end

    # Fallback: keyword matching
    keyword_match(question_text)
  rescue => e
    Rails.logger.warn "[QuestionnaireAutofill] Embedding search failed: #{e.message}. Falling back to keywords."
    keyword_match(question_text)
  end

  def find_by_embedding(question_embedding)
    # Search policies by description + title text similarity
    # We compute cosine similarity against policy text embeddings
    best_policy = nil
    best_score = 0

    @organization.policies.find_each do |policy|
      policy_text = [policy.title, policy.description].compact.join(' ')
      next if policy_text.blank?

      policy_embedding = Ai::Client.embed(policy_text, agent_name: "QuestionnaireAutofill")
      next unless policy_embedding.present?

      # Cosine similarity
      dot = question_embedding.zip(policy_embedding).sum { |a, b| a * b }
      mag_q = Math.sqrt(question_embedding.sum { |x| x**2 })
      mag_p = Math.sqrt(policy_embedding.sum { |x| x**2 })
      score = mag_q > 0 && mag_p > 0 ? dot / (mag_q * mag_p) : 0

      if score > best_score
        best_score = score
        best_policy = policy
      end
    end

    best_policy ? { policy: best_policy, score: [(best_score * 100).round(1), 99].min } : nil
  end

  def keyword_match(question_text)
    question_words = question_text.downcase.split(/\W+/).uniq.reject { |w| w.length < 3 }

    best_policy = nil
    best_score = 0

    @organization.policies.find_each do |policy|
      policy_words = (policy.title.to_s + ' ' + policy.description.to_s)
                      .downcase.split(/\W+/).uniq.reject { |w| w.length < 3 }

      overlap = (question_words & policy_words).size
      score = question_words.any? ? (overlap.to_f / question_words.size) : 0

      if score > best_score
        best_score = score
        best_policy = policy
      end
    end

    { policy: best_policy, score: best_score, words_matched: (best_score * question_words.size).round, method: :keyword }
  end

  def generate_answer(question_text, match)
    if match[:policy]
      # Use LLM to generate a professional answer grounded in policy text
      policy = match[:policy]
      policy_context = [policy.title, policy.description].compact.join("\n")

      prompt = <<~PROMPT
        You are a compliance officer answering a questionnaire about your organization's policies.
        Answer the following question based ONLY on the policy information provided below.
        Be professional, specific, and concise. If the policy doesn't fully address the question, say so.

        **Question**: #{question_text}

        **Relevant Policy — #{policy.title}**:
        #{policy_context.truncate(2000)}

        Provide a direct, professional answer suitable for inclusion in a compliance questionnaire response.
        Do not use markdown formatting.
      PROMPT

      response = Ai::Client.chat(
        prompt,
        task_type: :drafting,
        agent_name: "QuestionnaireAutofill",
        temperature: 0.3
      )

      {
        text: response.content,
        confidence: [match[:score].is_a?(Numeric) ? match[:score] : 70.0, 95].min
      }
    else
      {
        text: "This question requires manual review. No sufficiently matching policy was found in our library.",
        confidence: 10.0
      }
    end
  rescue => e
    Rails.logger.error "[QuestionnaireAutofill] LLM answer generation failed: #{e.message}"
    # Fallback to simple extraction
    if match[:policy]
      {
        text: "Per our #{match[:policy].title}: #{match[:policy].description.to_s.truncate(300)}",
        confidence: [(match[:score].to_f * 100).round(1), 60].min
      }
    else
      { text: "This question requires manual review.", confidence: 10.0 }
    end
  end
end
