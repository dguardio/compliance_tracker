class RegulationLibraryController < ApplicationController
  before_action :authenticate_user!
  before_action -> { require_feature!(:regulatory_intelligence) }
  before_action :set_organization

  # Shows only regulations adopted by this organization
  def index
    @q = @organization.regulations.ransack(params[:q])
    @regulations = @q.result(distinct: true).order(updated_at: :desc).page(params[:page]).per(20)
  end

  # Shows the global library for discovering new regulations to adopt
  def discover
    already_adopted_ids = @organization.organization_regulations.pluck(:regulation_id)
    @q = Regulation.where(status: 'active').where.not(id: already_adopted_ids).ransack(params[:q])
    @regulations = @q.result(distinct: true).order(updated_at: :desc).page(params[:page]).per(20)

    # Use org context for smart suggestions
    @org_keywords = @organization.compliance_keywords || []
    @org_jurisdictions = @organization.compliance_jurisdictions || []
    @org_industries = @organization.compliance_industries || []
  end

  def show
    @regulation = Regulation.find(params[:id])
    @adopted = @organization.organization_regulations.find_by(regulation_id: @regulation.id)
  end

  def adopt
    regulation = Regulation.find(params[:id])

    if @organization.organization_regulations.exists?(regulation_id: regulation.id)
      redirect_back fallback_location: regulation_library_path(regulation),
                    alert: "This regulation has already been adopted."
      return
    end

    @organization.organization_regulations.create!(
      regulation: regulation
    )

    redirect_to regulation_library_index_path,
                notice: "'#{regulation.title}' has been adopted into your organization."
  end

  def unadopt
    org_regulation = @organization.organization_regulations.find_by!(regulation_id: params[:id])
    org_regulation.destroy

    redirect_to regulation_library_index_path,
                notice: "Regulation has been removed from your organization."
  end

  private

  def set_organization
    @organization = current_user.organization
  end
end
