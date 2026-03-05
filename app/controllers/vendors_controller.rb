class VendorsController < ApplicationController
  before_action -> { require_feature!(:vendor_risk_management) }
  before_action :set_organization
  before_action :set_vendor, only: [:show, :edit, :update, :destroy]
  before_action :authorize_vendors

  def index
    @vendors = Vendor.where(organization: @organization).by_risk
    @vendors = @vendors.where(risk_tier: params[:risk_tier]) if params[:risk_tier].present?
    @vendors = @vendors.where(status: params[:status]) if params[:status].present?
    @expiring = Vendor.where(organization: @organization).contracts_expiring(30)
  end

  def show
    @assessments = @vendor.vendor_assessments.recent
  end

  def new
    @vendor = Vendor.new
  end

  def create
    @vendor = @organization.vendors.new(vendor_params)
    if @vendor.save
      redirect_to organization_vendor_path(@organization, @vendor), notice: 'Vendor created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @vendor.update(vendor_params)
      redirect_to organization_vendor_path(@organization, @vendor), notice: 'Vendor updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @vendor.destroy
    redirect_to organization_vendors_path(@organization), notice: 'Vendor removed.'
  end

  def assess
    @vendor = Vendor.where(organization: @organization).find(params[:id])
    assessment = @vendor.vendor_assessments.create!(
      organization: @organization,
      assessed_by: current_user,
      assessment_type: params[:assessment_type] || :periodic,
      status: :completed,
      risk_score: params[:risk_score].to_i,
      assessment_date: Date.current,
      next_review_date: 3.months.from_now,
      notes: params[:notes]
    )
    redirect_to organization_vendor_path(@organization, @vendor), notice: 'Assessment recorded.'
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_vendor
    @vendor = Vendor.where(organization: @organization).find(params[:id])
  end

  def vendor_params
    params.require(:vendor).permit(:name, :website, :risk_tier, :status, :description,
                                   :primary_contact_name, :primary_contact_email,
                                   :contract_start, :contract_end)
  end

  def authorize_vendors
    unless current_user.super_admin? ||
           current_user.has_role?('Admin', @organization) ||
           current_user.has_role?(:compliance_manager, @organization)
      redirect_to dashboard_path, alert: 'Not authorized.'
    end
  end
end
