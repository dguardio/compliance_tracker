class Admin::TableTemplatesController < ApplicationController
  def create
    @template = TableTemplate.new(template_params)
    
    # Set ownership based on scope
    if params[:scope] == 'organization'
      @template.organization = current_user.organization
      @template.category = "Organization"
    else
      @template.user = current_user
      @template.category = "Personal"
    end
    
    # Build columns JSON from selected custom columns
    if params[:column_ids].present?
      columns = CustomColumn.where(id: params[:column_ids]).map do |col|
        {
          name: col.name,
          prompt: col.prompt,
          column_type: col.column_type
        }
      end
      @template.columns = columns
    end
    
    if @template.save
      redirect_to admin_compliance_tables_path(custom_column_ids: params[:column_ids]), notice: 'Template saved successfully.'
    else
      redirect_to admin_compliance_tables_path(custom_column_ids: params[:column_ids]), alert: "Failed to save template: #{@template.errors.full_messages.join(', ')}"
    end
  end

  def apply
    template = TableTemplate.find(params[:id])
    
    created_columns = []
    failed_columns = []
    
    template.columns.each do |col_def|
      # Check if column with same name already exists for user
      existing = current_user.custom_columns.find_by(name: col_def['name'])
      
      if existing
        created_columns << existing
        next
      end
      
      new_column = current_user.custom_columns.build(
        name: col_def['name'],
        prompt: col_def['prompt'],
        column_type: col_def['column_type'],
        is_template: false
      )
      
      if new_column.save
        created_columns << new_column
      else
        failed_columns << col_def['name']
      end
    end
    
    # Add created columns to the selection in the URL
    current_selection = (params[:current_selection] || []).map(&:to_i)
    new_selection = (current_selection + created_columns.map(&:id)).uniq
    
    redirect_to admin_compliance_tables_path(custom_column_ids: new_selection), 
                notice: "Applied template '#{template.name}'. #{created_columns.count} columns added."
  end
  private

  def template_params
    params.require(:table_template).permit(:name, :description)
  end
end
