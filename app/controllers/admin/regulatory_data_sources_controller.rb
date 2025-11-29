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
    @regulatory_data_source = RegulatoryDataSource.new
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
      @discovered_sources = SourceDiscoveryAgent.new.call(sector: sector, jurisdiction: jurisdiction)
    end

    # Renders discover.html.erb by default
  end

  private

  def set_regulatory_data_source
    @regulatory_data_source = RegulatoryDataSource.find(params[:id])
  end

  def load_providers
    @providers = Provider.all.order(:name)
  end

  def regulatory_data_source_params
    params.require(:regulatory_data_source).permit(:name, :description, :source_type, :url, :status, :provider_id, sectors: [], jurisdictions: [], settings: {})
  end
end
