class Admin::RegulationsController < ApplicationController
  after_action :verify_authorized
  before_action :set_regulation, only: %i[show edit update destroy version workspace evidence]

  # GET /admin/regulations
  def index
    authorize Regulation
    scope = policy_scope(Regulation)
    
    # Ransack Search (Keyword)
    @q = scope.ransack(params[:q])
    
    regulations = if params[:semantic_search] == "1" && params[:q].present? && params[:q][:title_cont].present?
                    # Semantic Search: Use generic text query from title field
                    query = params[:q][:title_cont]
                    embedding = Ai::EmbeddingService.generate(query)
                    
                    if embedding
                      flash.now[:notice] = "Showing semantic search results for: '#{query}'"
                      scope.related_to(embedding)
                    else
                      flash.now[:alert] = "Could not generate vector for query."
                      scope
                    end
                  elsif params[:search_by_all].present?
                    scope.search_by_all(params[:search_by_all])
                  else
                    scope
                  end

    @regulations = @q.result.merge(regulations).order(created_at: :desc).page(params[:page])
  end

  # GET /admin/regulations/1
  def show
    authorize @regulation
  end

  # GET /admin/regulations/1/versions/:version_id
  def version
    authorize @regulation
    version = @regulation.versions.find(params[:version_id])
    @regulation = version.reify
    @is_historical_view = true
    flash.now[:notice] = "You are viewing a historical version of this regulation from #{version.created_at.strftime('%B %d, %Y %H:%M')}"
    render :show
  end

  # GET /admin/regulations/new
  def new
    @regulation = Regulation.new
    authorize @regulation
  end

  # GET /admin/regulations/1/edit
  def edit
    authorize @regulation
  end

  # POST /admin/regulations
  def create
    @regulation = Regulation.new(regulation_params)
    authorize @regulation

    if @regulation.save
      redirect_to admin_regulation_path(@regulation), notice: 'Regulation was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admin/regulations/1
  def update
    authorize @regulation
    if @regulation.update(regulation_params)
      redirect_to admin_regulation_path(@regulation), notice: 'Regulation was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/regulations/1
  def destroy
    authorize @regulation
    @regulation.destroy
    redirect_to admin_regulations_url, notice: 'Regulation was successfully destroyed.'
  end

  def bulk_delete
    authorize Regulation
    Regulation.where(id: params[:regulation_ids]).destroy_all
    redirect_to admin_regulations_url, notice: 'Selected regulations were successfully deleted.'
  end

  def download_diff
    @regulation = Regulation.find(params[:id])
    authorize @regulation
    @previous_regulation = Regulation.find_by(id: @regulation.previous_version_id)
    
    if @previous_regulation
      @diff_html = RegulationDiffService.new(@regulation, @previous_regulation).call
      
      respond_to do |format|
        format.html { render :diff }
        format.pdf do
          render pdf: "regulation_diff_#{@regulation.id}",
                 template: "admin/regulations/diff",
                 layout: 'pdf',
                 formats: [:html],
                 disposition: 'attachment'
        end
      end
    else
      redirect_to admin_regulation_path(@regulation), alert: "No previous version found to compare."
    end
  end

  def workspace
    authorize @regulation
    
    comments_scope = @regulation.comments.joins(:user)
    if defined?(current_organization) && current_organization
      comments_scope = comments_scope.where(users: { organization_id: current_organization.id })
      @users = current_organization.users.by_name.map { |u| { id: u.id, name: u.full_name } }
    elsif current_user.respond_to?(:organization_id)
      comments_scope = comments_scope.where(users: { organization_id: current_user.organization_id })
      @users = User.where(organization_id: current_user.organization_id).by_name.map { |u| { id: u.id, name: u.full_name } }
    else
      @users = []
    end

    @comments_json = comments_scope.order(created_at: :desc).map do |c|
      {
        id: c.id,
        content: c.content,
        user: c.user.full_name,
        created_at: c.created_at.strftime("%b %d, %Y"),
        selected_text: c.selected_text,
        start_index: c.start_index,
        end_index: c.end_index,
        comment_type: c.comment_type,
        suggested_text: c.suggested_text
      }
    end.to_json
    
    respond_to do |format|
      format.html { render :workspace, layout: 'application' }
      format.pdf do
        render pdf: "regulation_workspace_#{@regulation.id}",
               template: "admin/regulations/workspace",
               layout: 'pdf',
               formats: [:html],
               disposition: 'attachment',
               show_as_html: params[:debug].present?
      end
    end
  end

  def evidence
    authorize @regulation, :show?
    
    comments_scope = @regulation.comments.joins(:user)
    if defined?(current_organization) && current_organization
      comments_scope = comments_scope.where(users: { organization_id: current_organization.id })
    elsif current_user.respond_to?(:organization_id)
      comments_scope = comments_scope.where(users: { organization_id: current_user.organization_id })
    end

    @evidence_requests = comments_scope.where(comment_type: :evidence_request)
                                    .includes(:user, :assignee)
                                    .order(created_at: :desc)
                                    .page(params[:page])
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_regulation
      @regulation = Regulation.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def regulation_params
      params.require(:regulation).permit(:title, :agency, :jurisdiction, :reg_type, :revision, :effective_date, :status, :full_text, :files, :metadata, :external_id, :previous_version_id)
    end
end
