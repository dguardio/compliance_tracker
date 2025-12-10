require 'csv'

class ComplianceFrameworkImporter
  def initialize(organization, file_path)
    @organization = organization
    @file_path = file_path
    @errors = []
  end

  def import
    ActiveRecord::Base.transaction do
      process_csv
      raise ActiveRecord::Rollback if @errors.any?
    end
    @errors.empty?
  end

  def errors
    @errors
  end

  private

  def process_csv
    current_framework = nil
    current_requirement = nil

    CSV.foreach(@file_path, headers: true) do |row|
      # Expected headers: Framework, Requirement, Control, Control Description

      framework_name = row['Framework']&.strip
      requirement_name = row['Requirement']&.strip
      control_name = row['Control']&.strip
      control_desc = row['Control Description']&.strip

      next if framework_name.blank?

      # Find or create Framework
      if current_framework.nil? || current_framework.name != framework_name
        current_framework = @organization.compliance_frameworks.find_or_create_by!(name: framework_name) do |f|
          f.status = 'active'
          f.version = '1.0'
        end
      end

      # Find or create Requirement
      if requirement_name.present? && (current_requirement.nil? || current_requirement.name != requirement_name)
        current_requirement = current_framework.compliance_requirements.find_or_create_by!(name: requirement_name) do |r|
          r.description = requirement_name # Default description
        end
      end

      # Create Control
      if control_name.present? && current_requirement.present?
        current_requirement.compliance_controls.find_or_create_by!(name: control_name) do |c|
          c.description = control_desc || control_name
          c.organization = @organization
        end
      end

    rescue ActiveRecord::RecordInvalid => e
      @errors << "Row #{$.}: #{e.message}"
    end
  end
end
