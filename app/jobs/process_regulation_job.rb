# frozen_string_literal: true

# Job to process a single regulation using the RegulationProcessorService.
# This is typically enqueued after a regulation is scraped.
class ProcessRegulationJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 10

  def perform(regulation_id)
    regulation = Regulation.find_by(id: regulation_id)
    unless regulation
      Rails.logger.warn "ProcessRegulationJob could not find Regulation with ID #{regulation_id}"
      return
    end

    Rails.logger.info "Starting processing for Regulation ID: #{regulation.id}"
    Ai::RegulationSupervisor.new.process(regulation)
    Rails.logger.info "Finished processing for Regulation ID: #{regulation.id}"

    # After processing, analyze impact for all organizations
    Ai::ImpactAnalysisAgent.analyze_impact_for_all_orgs(regulation)
  end
end
