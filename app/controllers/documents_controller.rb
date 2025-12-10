class DocumentsController < ApplicationController
  before_action :set_organization
  before_action :set_document, only: %i[show edit update destroy approve reject archive duplicate]
  before_action :authorize_document

  def index
    @documents = @organization.documents
                              .includes(:uploaded_by, :approved_by, :compliance_framework, :compliance_requirement, :compliance_control)
                              .page(params[:page]).per(20)

    # Apply filters
    @documents = @documents.by_category(params[:category]) if params[:category].present?
    @documents = @documents.by_status(params[:status]) if params[:status].present?
    @documents = @documents.by_framework(params[:framework_id]) if params[:framework_id].present?
    @documents = @documents.by_requirement(params[:requirement_id]) if params[:requirement_id].present?
    @documents = @documents.by_control(params[:control_id]) if params[:control_id].present?

    # Apply search
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @documents = @documents.where(
        'documents.title ILIKE ? OR documents.description ILIKE ? OR documents.category ILIKE ?',
        search_term, search_term, search_term
      )
    end

    # Apply sorting
    @documents = case params[:sort]
                 when 'title'
                   @documents.order(:title)
                 when 'created_at'
                   @documents.order(:created_at)
                 when 'updated_at'
                   @documents.order(:updated_at)
                 when 'status'
                   @documents.order(:status)
                 else
                   @documents.recent
                 end

    @categories = @organization.documents.distinct.pluck(:category).compact.sort
    @statuses = Document.statuses.keys
    @compliance_frameworks = @organization.compliance_frameworks
  end

  def show
    @document_versions = @document.versions.order(created_at: :desc)
  end

  def new
    @document = @organization.documents.build
    @compliance_frameworks = @organization.compliance_frameworks
    @compliance_requirements = []
    @compliance_controls = []
  end

  def create
    @document = @organization.documents.build(document_params)
    @document.uploaded_by = current_user

    if @document.save
      redirect_to organization_document_path(@organization, @document),
                  notice: 'Document was successfully uploaded.'
    else
      @compliance_frameworks = @organization.compliance_frameworks
      @compliance_requirements = @document.compliance_framework&.compliance_requirements || []
      @compliance_controls = @document.compliance_requirement&.compliance_controls || []
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @compliance_frameworks = @organization.compliance_frameworks
    @compliance_requirements = @document.compliance_framework&.compliance_requirements || []
    @compliance_controls = @document.compliance_requirement&.compliance_controls || []
  end

  def update
    if @document.update(document_params)
      redirect_to organization_document_path(@organization, @document),
                  notice: 'Document was successfully updated.'
    else
      @compliance_frameworks = @organization.compliance_frameworks
      @compliance_requirements = @document.compliance_framework&.compliance_requirements || []
      @compliance_controls = @document.compliance_requirement&.compliance_controls || []
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @document.destroy
    redirect_to organization_documents_path(@organization),
                notice: 'Document was successfully deleted.'
  end

  def approve
    if @document.approve!(current_user)
      redirect_to organization_document_path(@organization, @document),
                  notice: 'Document was successfully approved.'
    else
      redirect_to organization_document_path(@organization, @document),
                  alert: 'You are not authorized to approve this document.'
    end
  end

  def reject
    reason = params[:rejection_reason]
    if @document.reject!(current_user, reason)
      redirect_to organization_document_path(@organization, @document),
                  notice: 'Document was rejected.'
    else
      redirect_to organization_document_path(@organization, @document),
                  alert: 'You are not authorized to reject this document.'
    end
  end

  def archive
    @document.archive!
    redirect_to organization_document_path(@organization, @document),
                notice: 'Document was archived.'
  end

  def duplicate
    new_document = @document.duplicate!
    redirect_to organization_document_path(@organization, new_document),
                notice: 'Document was duplicated.'
  end

  def submit_for_review
    @document = @organization.documents.find(params[:id])
    @document.submit_for_review!
    redirect_to organization_document_path(@organization, @document),
                notice: 'Document submitted for review.'
  end

  # AJAX endpoints for dynamic form updates
  def get_requirements
    framework = @organization.compliance_frameworks.find(params[:framework_id])
    requirements = framework.compliance_requirements.map { |r| { id: r.id, name: r.name } }
    render json: requirements
  end

  def get_controls
    requirement = @organization.compliance_requirements.find(params[:requirement_id])
    controls = requirement.compliance_controls.map { |c| { id: c.id, name: c.name } }
    render json: controls
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_document
    @document = @organization.documents.find(params[:id])
  end

  def authorize_document
    case action_name
    when 'index'
      authorize Document.new(organization: @organization), :index?
    when 'show'
      authorize @document, :show?
    when 'new', 'create'
      authorize Document.new(organization: @organization), :create?
    when 'edit', 'update'
      authorize @document, :update?
    when 'destroy'
      authorize @document, :destroy?
    when 'approve', 'reject'
      authorize @document, :approve?
    when 'archive', 'duplicate', 'submit_for_review'
      authorize @document, :update?
    end
  end

  def document_params
    params.require(:document).permit(
      :title, :description, :category, :status, :expires_at,
      :compliance_framework_id, :compliance_requirement_id, :compliance_control_id,
      :workflow_template_id,
      :file, :tags, :document_type, :department, :team, :unit,
      :review_cycle, :approval_workflow, :custom_fields, :metadata
    )
  end
end
