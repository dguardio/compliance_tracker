require "rails_helper"

RSpec.describe EvidenceMailer, type: :mailer do
  describe "request_email" do
    let(:mail) { EvidenceMailer.request_email }

    it "renders the headers" do
      expect(mail.subject).to eq("Request email")
      expect(mail.to).to eq(["to@example.org"])
      expect(mail.from).to eq(["from@example.com"])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi")
    end
  end

end
