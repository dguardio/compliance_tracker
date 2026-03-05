class EnableCoreFeaturesForExistingOrganizations < ActiveRecord::Migration[7.1]
  def up
    # Core flags that should be enabled for all existing organizations
    core_flags = %i[
      compliance_management
      risk_management
      document_management
      policies
      regulatory_intelligence
    ]

    Organization.find_each do |org|
      core_flags.each do |flag|
        Flipper.enable(flag, org)
      end
      Rails.logger.info "Enabled #{core_flags.size} core flags for Organization##{org.id} (#{org.name})"
    end

    Rails.logger.info "Migration complete: enabled core flags for #{Organization.count} organizations."
  end

  def down
    core_flags = %i[
      compliance_management
      risk_management
      document_management
      policies
      regulatory_intelligence
    ]

    Organization.find_each do |org|
      core_flags.each do |flag|
        Flipper.disable(flag, org)
      end
    end
  end
end
