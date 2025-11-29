# Preview all emails at http://localhost:3000/rails/mailers/evidence_mailer
class EvidenceMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/evidence_mailer/request_email
  def request_email
    EvidenceMailer.request_email
  end

end
