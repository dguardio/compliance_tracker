# frozen_string_literal: true

# Service to process raw regulation data, clean it, and extract metadata.
#
# This service acts as an ORCHESTRATOR — it delegates the actual AI work
# to RegulationSupervisor (which runs MetadataExtractorAgent + RequirementSplittingAgent
# in parallel via Async).
#
# Previously this service had its own inline LLM call that duplicated
# the work done by MetadataExtractorAgent and RequirementSplittingAgent.
# That duplication has been removed — there is now a single source of truth
# for regulation processing.
#
class RegulationProcessorService
  # Main entry point to process a regulation.
  #
  # @param regulation [Regulation] The regulation to process.
  def process(regulation)
    Rails.logger.info "Processing regulation: #{regulation.title}"

    # Delegate all AI work to the RegulationSupervisor
    # which runs MetadataExtractorAgent + RequirementSplittingAgent in parallel.
    Ai::RegulationSupervisor.new.process(regulation)

    Rails.logger.info "Finished processing regulation: #{regulation.title}"
  rescue => e
    Rails.logger.error "Failed to process regulation ##{regulation.id}: #{e.message}"
    raise
  end
end

