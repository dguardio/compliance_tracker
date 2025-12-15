require 'rails_helper'

RSpec.describe Ai::OrchestratorAgent do
  describe '#execute' do
    let(:intention) { "Create a data retention policy" }
    
    # Mock Agents
    let(:writer_double) { instance_double(Ai::Agents::PolicyWriterAgent) }
    let(:reviewer_double) { instance_double(Ai::Agents::PolicyReviewerAgent) }
    
    before do
      allow(Ai::Agents::PolicyWriterAgent).to receive(:new).and_return(writer_double)
      allow(Ai::Agents::PolicyReviewerAgent).to receive(:new).and_return(reviewer_double)
    end

    it 'coordinates the writer and reviewer agents' do
      # Expect Writer to be called
      expect(writer_double).to receive(:run)
        .with(topic: "data retention")
        .and_return("# Draft Policy")

      # Expect Reviewer to be called with the draft
      expect(reviewer_double).to receive(:run)
        .with(policy_content: "# Draft Policy", topic: "data retention")
        .and_return({ score: 90, findings: [] })

      result = subject.execute(intention: intention)

      expect(result[:topic]).to eq("data retention")
      expect(result[:review_score]).to eq(90)
      expect(result[:draft_content]).to eq("# Draft Policy")
    end
  end
end
