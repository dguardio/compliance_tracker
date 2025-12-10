class AddWorkflowTemplateToDocuments < ActiveRecord::Migration[7.1]
  def change
    add_reference :documents, :workflow_template, null: true, foreign_key: true
  end
end
