# frozen_string_literal: true

module Ai
  class OrganizationProfileGenerator
    def initialize(organization)
      @organization = organization
    end

    def generate
      # In a real app, this would call an LLM (Gemini/OpenAI) with the organization's name/domain.
      # For now, we simulate this with a robust heuristic/mock based on industry keywords in the name.
      
      name = @organization.name.downcase
      domain = @organization.domain.downcase

      if name.include?("health") || name.include?("care") || domain.include?("med")
        {
          industries: ["Healthcare", "Biotechnology", "Pharmaceuticals"],
          keywords: ["HIPAA", "FDA", "Patient Data", "Clinical Trials", "PHI"],
          exclusion_terms: ["Finance", "Retail", "Manufacturing"]
        }
      elsif name.include?("bank") || name.include?("fin") || domain.include?("bank")
        {
          industries: ["Finance", "Banking", "Fintech"],
          keywords: ["SOX", "GLBA", "PCI-DSS", "Anti-Money Laundering", "KYC"],
          exclusion_terms: ["Healthcare", "HIPAA", "Manufacturing"]
        }
      elsif name.include?("tech") || domain.include?("io") || domain.include?("ai")
        {
          industries: ["Technology", "SaaS", "Cloud Computing"],
          keywords: ["GDPR", "SOC2", "ISO 27001", "CCPA", "Data Privacy"],
          exclusion_terms: ["Heavy Industry", "Agriculture"]
        }
      else
        # Default Generic Profile
        {
          industries: ["General Business", "Technology"],
          keywords: ["Data Privacy", "Employment Law", "Tax Compliance"],
          exclusion_terms: ["Specialized Industry Regulations"]
        }
      end
    end
  end
end
