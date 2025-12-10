class EvidenceRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_organization
  before_action :set_evidence_request, only: %i[show edit update destroy]

  def index
    @evidence_requests = @organization.evidence_requests.includes(:assigned_to, :compliance_requirement, :compliance_control).order(due_date: :asc)
  end

  def show
  end

  def new
    @evidence_request = @organization.evidence_requests.new
  end

  def edit
  end

  def create
    @evidence_request = @organization.evidence_requests.new(evidence_request_params)

    if @evidence_request.save
      redirect_to organization_evidence_request_path(@organization, @evidence_request), notice: 'Evidence request was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @evidence_request.update(evidence_request_params)
      redirect_to organization_evidence_request_path(@organization, @evidence_request), notice: 'Evidence request was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @evidence_request.destroy
    redirect_to organization_evidence_requests_path(@organization), notice: 'Evidence request was successfully destroyed.'
  end

  def download_all
    @evidence_request = @organization.evidence_requests.find(params[:id])
    
    filename = "evidence_request_#{@evidence_request.id}_files.zip"
    temp_file = Tempfile.new(filename)

    begin
      require 'zip'
      Zip::File.open(temp_file.path, Zip::File::CREATE) do |zipfile|
        # Add attached files
        @evidence_request.files.each do |file|
          zipfile.get_output_stream("attachments/#{file.filename}") { |f| f.write file.download }
        end

        # Add linked documents
        @evidence_request.documents.each do |doc|
          if doc.file.attached?
            zipfile.get_output_stream("documents/#{doc.file.filename}") { |f| f.write doc.file.download }
          end
        end
      end

      zip_data = File.read(temp_file.path)
      send_data(zip_data, type: 'application/zip', disposition: 'attachment', filename: filename)
    ensure
      temp_file.close
      temp_file.unlink
    end
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
    authorize @organization, :show?
  end

  def set_evidence_request
    @evidence_request = @organization.evidence_requests.find(params[:id])
  end

  def evidence_request_params
    params.require(:evidence_request).permit(:title, :description, :status, :due_date, :assigned_to_id, :compliance_requirement_id, :compliance_control_id, files: [], document_ids: [])
  end
end
