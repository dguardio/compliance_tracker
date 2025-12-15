class Admin::CustomColumnsController < ApplicationController
  before_action :set_custom_column, only: [:show, :edit, :update, :destroy, :extract]

  def index
    @custom_columns = current_user.custom_columns.order(created_at: :desc)
    @templates = CustomColumn.templates
  end

  def show
  end

  def new
    @custom_column = CustomColumn.new
  end

  def create
    @custom_column = current_user.custom_columns.build(custom_column_params)
    
    if @custom_column.save
      if params[:current_selection].present?
        # If coming from Active Tables, preserve selection and add new column
        current_selection = params[:current_selection].map(&:to_i)
        new_selection = (current_selection + [@custom_column.id]).uniq
        redirect_to admin_compliance_tables_path(custom_column_ids: new_selection), notice: 'Custom column created successfully.'
      elsif params[:redirect_to].present?
        redirect_to params[:redirect_to], notice: 'Custom column created successfully.'
      else
        redirect_to admin_custom_columns_path, notice: 'Custom column created successfully.'
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @custom_column.update(custom_column_params)
      redirect_to admin_custom_columns_path, notice: 'Custom column updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @custom_column.destroy
    redirect_to admin_custom_columns_path, notice: 'Custom column deleted successfully.'
  end

  # Trigger AI extraction for all regulations
  def extract
    # Run extraction in background for better UX
    ExtractCustomColumnJob.perform_later(@custom_column.id)
    
    redirect_to admin_custom_columns_path, notice: 'Extraction started. This may take a few minutes.'
  end

  # Trigger AI extraction for multiple columns
  def extract_all
    if params[:custom_column_ids].present?
      params[:custom_column_ids].each do |id|
        ExtractCustomColumnJob.perform_later(id)
      end
      redirect_back fallback_location: admin_compliance_tables_path, notice: "Extraction started for #{params[:custom_column_ids].count} columns."
    else
      redirect_back fallback_location: admin_compliance_tables_path, alert: "No columns selected for extraction."
    end
  end

  # Apply a full template (creates multiple columns)
  def apply_template
    template = TableTemplate.find(params[:id])
    
    # Batch create columns
    created_columns = []
    
    if template.columns.is_a?(Array)
      template.columns.each do |col_data|
        # Skip if column with this name already exists for user to avoid dupes
        next if current_user.custom_columns.exists?(name: col_data['name'])
        
        column = current_user.custom_columns.build(
          name: col_data['name'],
          prompt: col_data['prompt'],
          column_type: col_data['column_type'] || 'text',
          is_template: false
        )
        created_columns << column if column.save
      end
    end
    
    if created_columns.any?
      # Add new columns to the current view selection
      current_selection = (params[:custom_column_ids] || []).map(&:to_i)
      new_selection = (current_selection + created_columns.map(&:id)).uniq
      
      redirect_to admin_compliance_tables_path(custom_column_ids: new_selection), 
        notice: "#{created_columns.count} columns added from '#{template.name}' template."
    else
      redirect_back fallback_location: admin_compliance_tables_path, 
        alert: "No new columns were added. You might already have all columns from this template."
    end
  end

  private

  def set_custom_column
    @custom_column = current_user.custom_columns.find(params[:id])
  end

  def custom_column_params
    params.require(:custom_column).permit(:name, :prompt, :column_type, :is_template)
  end
end
