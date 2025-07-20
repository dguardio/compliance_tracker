class Admin::RegulationsController < ApplicationController
  before_action :set_regulation, only: %i[show edit update destroy]

  # GET /admin/regulations
  def index
    @regulations = Regulation.all.order(created_at: :desc)
  end

  # GET /admin/regulations/1
  def show
  end

  # GET /admin/regulations/new
  def new
    @regulation = Regulation.new
  end

  # GET /admin/regulations/1/edit
  def edit
  end

  # POST /admin/regulations
  def create
    @regulation = Regulation.new(regulation_params)

    if @regulation.save
      redirect_to admin_regulation_path(@regulation), notice: 'Regulation was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /admin/regulations/1
  def update
    if @regulation.update(regulation_params)
      redirect_to admin_regulation_path(@regulation), notice: 'Regulation was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /admin/regulations/1
  def destroy
    @regulation.destroy
    redirect_to admin_regulations_url, notice: 'Regulation was successfully destroyed.'
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
