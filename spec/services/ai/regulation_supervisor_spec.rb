require 'rails_helper'

RSpec.describe Ai::RegulationSupervisor do
  let(:regulation) { create(:regulation, full_text: { "main" => "Some long legal text" }) }
  let(:supervisor) { described_class.new }
  
  # Agent Mocks
  let(:metadata_agent) { instance_double(Ai::Agents::MetadataExtractorAgent) }
  let(:requirements_agent) { instance_double(Ai::Agents::RequirementSplittingAgent) }

  before do
    allow(Ai::Agents::MetadataExtractorAgent).to receive(:new).and_return(metadata_agent)
    allow(Ai::Agents::RequirementSplittingAgent).to receive(:new).and_return(requirements_agent)
    
    # Mock GenerateEmbeddingJob to run inline or be enqueued
    allow(GenerateEmbeddingJob).to receive(:perform_later)
    allow(RegulationDocumentService).to receive_message_chain(:new, :attach_document)
  end

  describe '#process' do
    it 'runs agents and updates the regulation' do
      # Agent Returns
      allow(metadata_agent).to receive(:run).and_return({ jurisdiction: 'EU', summary: 'A summary' })
      allow(requirements_agent).to receive(:run).and_return([{ title: 'Req 1', description: 'Do X' }])

      # We can't easily test Async/Await inside RSpec without special setup, 
      # so we assume the class handles the concurrency correctly and just verify the outcome.
      # If Async is used, the agents will still be called.
      
      supervisor.process(regulation)
      
      regulation.reload
      
      # Verify Metadata Update
      expect(regulation.jurisdiction).to eq('EU')
      expect(regulation.metadata['summary']).to eq('A summary')
      
      # Verify Requirement Creation
      expect(regulation.standard_requirements.count).to eq(1)
      expect(regulation.standard_requirements.first.name).to eq('Req 1')
      
      # Verify Job Enqueue
      expect(GenerateEmbeddingJob).to have_received(:perform_later).at_least(:once)
    end
  end
end
