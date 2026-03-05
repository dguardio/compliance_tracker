# frozen_string_literal: true

class Admin::RegulatoryDataSourcesController < ApplicationController
  after_action :verify_authorized
  before_action :set_regulatory_data_source, only: %i[show edit update destroy]
  before_action :load_providers, only: %i[new create edit update]

  def index
    authorize RegulatoryDataSource
    @regulatory_data_sources = RegulatoryDataSource.includes(:provider).all.order("providers.name, regulatory_data_sources.name")
  end

  def show
    authorize @regulatory_data_source
  end

  def new
    @regulatory_data_source = RegulatoryDataSource.new(
      name: params[:name],
      url: params[:url],
      source_type: params[:source_type]
    )
    authorize @regulatory_data_source
  end

  def edit
    authorize @regulatory_data_source
  end

  def create
    @regulatory_data_source = RegulatoryDataSource.new(regulatory_data_source_params)
    authorize @regulatory_data_source

    if @regulatory_data_source.save
      redirect_to admin_regulatory_data_source_path(@regulatory_data_source), notice: 'Regulatory data source was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    authorize @regulatory_data_source
    if @regulatory_data_source.update(regulatory_data_source_params)
      redirect_to admin_regulatory_data_source_path(@regulatory_data_source), notice: 'Regulatory data source was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @regulatory_data_source
    @regulatory_data_source.destroy
    redirect_to admin_regulatory_data_sources_url, notice: 'Regulatory data source was successfully destroyed.'
  end

  def bulk_delete
    authorize RegulatoryDataSource
    RegulatoryDataSource.where(id: params[:regulatory_data_source_ids]).destroy_all
    redirect_to admin_regulatory_data_sources_url, notice: 'Selected data sources were successfully deleted.'
  end

  def discover
    authorize RegulatoryDataSource, :discover? # Authorize the action

    if request.post?
      sector = params[:sector]
      jurisdiction = params[:jurisdiction]
      @discovered_sources = Ai::Agents::SourceDiscoveryAgent.new.call(sector: sector, jurisdiction: jurisdiction)
    end

    # Renders discover.html.erb by default
  end

  def run_discovery
    authorize RegulatoryDataSource, :discover?
    
    # Trigger the agent asynchronously
    # In a real app, this would be a Job: Ai::RegulatoryDiscoveryAgentJob.perform_later(params[:topics])
    # For now, we call the service directly (or wrap it in a Thread/Job as per project patterns)
    
    Thread.new do
      # 1. Run the targeted scouts on known sources
      Rails.logger.info "Running Targeted Discovery Supervisor..."
      Ai::DiscoverySupervisor.new.run_all
      
      # 2. Run the wild watchdog search
      Rails.logger.info "Running Wild Watchdog..."
      Ai::RegulatoryDiscoveryAgent.run_global_scan
    end
    
    redirect_to admin_regulatory_data_sources_path, notice: 'Global Regulatory Watchdog initiated 🐕. Check logs for progress.'
  end

  def preview_config
    authorize RegulatoryDataSource, :create?
    
    # Create a temporary object to hold the docs (not saved)
    temp_source = RegulatoryDataSource.new(
      documentation_url: params[:documentation_url],
      documentation_content: params[:documentation_content]
    )
    
    begin
      config = Ai::SmartConfiguratorService.new(temp_source).preview
      
      if config
        render json: config
      else
        render json: { error: 'Could not configure source from documentation.' }, status: :unprocessable_entity
      end
    rescue StandardError => e
      render json: { error: e.message }, status: :unprocessable_entity
    end
  end

  private

  def set_regulatory_data_source
    @regulatory_data_source = RegulatoryDataSource.find(params[:id])
  end

  def load_providers
    @providers = Provider.all.order(:name)
  end

  def regulatory_data_source_params
    params.require(:regulatory_data_source).permit(:name, :description, :source_type, :url, :status, :provider_id, :api_key, :api_key_param, :documentation_url, :documentation_content, sectors: [], jurisdictions: [], settings: {})
  end
end
