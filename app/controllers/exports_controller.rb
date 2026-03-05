require 'csv'

class ExportsController < ApplicationController
  include ComplianceExportable
  before_action :authenticate_user!
  before_action -> { require_feature!(:compliance_exports) }
  before_action :set_organization

  def frameworks
    csv_data = export_frameworks_csv(@organization)
    send_data csv_data,
              filename: "#{@organization.slug}_frameworks_#{Date.current.iso8601}.csv",
              type: 'text/csv',
              disposition: 'attachment'
  end

  def requirements
    framework = params[:framework_id] ? @organization.compliance_frameworks.find(params[:framework_id]) : nil
    csv_data = export_requirements_csv(@organization, framework)
    filename = framework ? "#{framework.slug}_requirements" : "all_requirements"
    send_data csv_data,
              filename: "#{@organization.slug}_#{filename}_#{Date.current.iso8601}.csv",
              type: 'text/csv',
              disposition: 'attachment'
  end

  def controls
    framework = params[:framework_id] ? @organization.compliance_frameworks.find(params[:framework_id]) : nil
    csv_data = export_controls_csv(@organization, framework)
    filename = framework ? "#{framework.slug}_controls" : "all_controls"
    send_data csv_data,
              filename: "#{@organization.slug}_#{filename}_#{Date.current.iso8601}.csv",
              type: 'text/csv',
              disposition: 'attachment'
  end

  def risk_assessments
    csv_data = export_risk_assessments_csv(@organization)
    send_data csv_data,
              filename: "#{@organization.slug}_risk_assessments_#{Date.current.iso8601}.csv",
              type: 'text/csv',
              disposition: 'attachment'
  end

  private

  def set_organization
    @organization = current_user.organization
  end
end
