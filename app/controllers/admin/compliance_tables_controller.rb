class Admin::ComplianceTablesController < ApplicationController
  def index
    # Only show regulations assigned to the user's organization
    base_scope = Regulation.for_organization(current_user.organization)
    
    @q = base_scope.ransack(params[:q])
    @regulations = @q.result(distinct: true).page(params[:page]).per(20)
    
    # Load selected custom columns
    @selected_column_ids = params[:custom_column_ids] || []
    @custom_columns = current_user.custom_columns.where(id: @selected_column_ids) if @selected_column_ids.any?
    @custom_columns ||= []
    
    # Eager load extractions for performance
    if @custom_columns.any?
      @regulations = @regulations.includes(:regulation_extractions)
    end
    
    # Extract unique values for filters (from organization's regulations only)
    # @agencies = base_scope.distinct.pluck(:agency).compact.sort
    # @jurisdictions = base_scope.distinct.pluck(:jurisdiction).compact.sort
    # @topics = base_scope.map { |r| r.metadata['topics'] }.flatten.compact.uniq.sort
    
    # All available custom columns for selection
    @available_columns = current_user.custom_columns.order(:name)
    
    # Load Workflow Templates
    @workflow_templates = TableTemplate.available_for(current_user).group_by(&:category)
    
    respond_to do |format|
      format.html
      format.xlsx {
        response.headers['Content-Disposition'] = "attachment; filename=\"compliance_table_#{Date.today}.xlsx\""
      }
    end
  end
end
