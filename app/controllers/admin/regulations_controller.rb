class Admin::RegulationsController < ApplicationController
  after_action :verify_authorized
  before_action :set_regulation, only: %i[show edit update destroy version]

  # GET /admin/regulations
  def index
    authorize Regulation
    @q = Regulation.ransack(params[:q])
    
    regulations = if params[:search_by_all].present?
                    Regulation.search_by_all(params[:search_by_all])
                  else
                    Regulation.all
                  end

    @regulations = @q.result(distinct: true).merge(regulations).order(created_at: :desc).page(params[:page])
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_regulation
      @regulation = Regulation.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def regulation_params
      params.require(:regulation).permit(:title, :agency, :jurisdiction, :reg_type, :version, :effective_date, :status, :full_text, :files, :metadata, :external_id, :previous_version_id)
    end
end
