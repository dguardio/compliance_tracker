require 'rails_helper'

RSpec.describe SourceDiscoveryAgent do
  describe '#call' do
    let(:google_tool) { instance_double(Ai::Tools::GoogleSearchTool) }
    let(:web_walker) { instance_double(Ai::Adapters::WebWalker) }
    
    before do
      allow(Ai::Tools::GoogleSearchTool).to receive(:new).and_return(google_tool)
      allow(Ai::Adapters::WebWalker).to receive(:new).and_return(web_walker)
      
      # Mock LLM for RubyLLM.chat.ask
      allow(RubyLLM).to receive_message_chain(:chat, :ask, :content).and_return(
        { is_relevant: true, name: "EPA", source_type: "web_scrape" }.to_json
      )
    end

    it 'searches google and visits results' do
      # 1. Expect Google Search
      search_results = [{ link: "http://epa.gov", title: "EPA" }].to_json
      expect(google_tool).to receive(:execute).and_return(search_results)
      
      # 2. Expect Web Visit
      expect(web_walker).to receive(:extract).with("http://epa.gov").and_return({ title: "EPA Home", full_text: "Welcome to EPA" })
      
      results = subject.call(sector: 'Environment', jurisdiction: 'US')
      
      expect(results.first[:name]).to eq('EPA')
      expect(results.first[:url]).to eq('http://epa.gov')
    end
  end
end
