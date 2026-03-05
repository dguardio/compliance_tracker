class Admin::OrganizationRegulationsController < ApplicationController
  before_action :set_organization

  def index
    @organization_regulations = @organization.organization_regulations
                                             .includes(:regulation)
                                             .order(priority: :desc, created_at: :desc)
                                             .page(params[:page]).per(20)
  end

  def available
    search_params = params[:q] || {}
    
    if params[:smart_search] == '1' && search_params[:title_cont].present?
      original_term = search_params[:title_cont]
      expanded_terms = Ai::SearchService.expand_query(original_term)
      
      # If we got expanded terms, we search for ANY of them OR the original term
      if expanded_terms.any?
        # We need to construct a more complex query. 
        # Ransack doesn't easily support "OR" across a list of values for a 'cont' search 
        # without using a group.
        # So we'll use a custom scope or just ransack's group feature if possible, 
        # or simply join them for a 'cont_any' if supported, or 'title_cont_any'
        
        # title_cont_any expects an array of strings
        search_params[:title_cont_any] = [original_term] + expanded_terms
        search_params.delete(:title_cont) # Remove the single container search
        
        flash.now[:notice] = "Smart Search active: Searched for '#{original_term}' and related terms: #{expanded_terms.join(', ')}"
      end
    end

    @q = Regulation.available_for_organization(@organization).ransack(search_params)
    @regulations = @q.result(distinct: true).page(params[:page]).per(20)
    
    # For filters
    @agencies = Regulation.distinct.pluck(:agency).compact.sort
    @jurisdictions = Regulation.distinct.pluck(:jurisdiction).compact.sort
  end

  def create
    regulation = Regulation.find(params[:regulation_id])
    
    @organization.add_regulation(
      regulation,
      assigned_by: current_user,
      notes: params[:notes],
      priority: params[:priority] || 0
    )
    
    redirect_to admin_organization_regulations_path, notice: 'Regulation added successfully.'
  rescue ActiveRecord::RecordInvalid => e
    redirect_to available_admin_organization_regulations_path, alert: "Failed to add regulation: #{e.message}"
  end

  def destroy
    @org_regulation = @organization.organization_regulations.find(params[:id])
    @org_regulation.destroy
    
    redirect_to admin_organization_regulations_path, notice: 'Regulation removed from organization.'
  end

  def update_status
    @org_regulation = @organization.organization_regulations.find(params[:id])
    @org_regulation.update!(status: params[:status])
    
    redirect_to admin_organization_regulations_path, notice: 'Status updated successfully.'
  end

  private

  def set_organization
    @organization = current_user.organization
  end
end
