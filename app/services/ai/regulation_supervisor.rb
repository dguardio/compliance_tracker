require 'async'

module Ai
  class RegulationSupervisor
    def process(regulation)
      Rails.logger.info "Supervisor starting for Regulation ##{regulation.id}"
      
      text = clean_text(regulation.full_text)
      
      metadata_task = nil
      requirements_task = nil
      metadata = {}
      requirements = []

      # Run agents in parallel
      Async do |task|
        metadata_task = task.async do
          Ai::Agents::MetadataExtractorAgent.new(text).run
        end

        requirements_task = task.async do
          Ai::Agents::RequirementSplittingAgent.new(text).run
        end
        
        metadata = metadata_task.wait
        requirements = requirements_task.wait
      end.wait

      update_regulation(regulation, metadata, requirements)
      
      Rails.logger.info "Supervisor finished for Regulation ##{regulation.id}"
    end

    private

    def clean_text(raw_text)
      text_content = raw_text.is_a?(Hash) ? raw_text.values.join("\n") : raw_text.to_s
      text_content.strip.gsub(/\s+/, ' ')
    end

    def update_regulation(regulation, metadata, requirements)
      return if metadata.blank? && requirements.blank?

      update_attributes = {
        jurisdiction: metadata[:jurisdiction] || regulation.jurisdiction,
        agency: metadata[:agency] || regulation.agency,
        effective_date: metadata[:effective_date] || regulation.effective_date,
        metadata: regulation.metadata.merge(metadata)
      }

      if regulation.update(update_attributes)
        GenerateEmbeddingJob.perform_later(regulation)
        create_standard_requirements(regulation, requirements)
        RegulationDocumentService.new.attach_document(regulation)
      end
    end

    def create_standard_requirements(regulation, requirements_data)
      return unless requirements_data.is_a?(Array)

      requirements_data.each_with_index do |req_data, index|
        external_id = "#{regulation.id}-REQ-#{index + 1}"
        regulation.standard_requirements.find_or_initialize_by(external_id: external_id).tap do |sr|
          sr.name = req_data[:title].presence || "Requirement #{index + 1}"
          sr.description = req_data[:description]
          sr.category = req_data[:topic] || req_data[:action_type] || 'General'
          sr.save!
          GenerateEmbeddingJob.perform_later(sr)
        end
      end
    end
  end
end
