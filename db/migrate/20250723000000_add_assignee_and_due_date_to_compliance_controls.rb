# frozen_string_literal: true

class AddAssigneeAndDueDateToComplianceControls < ActiveRecord::Migration[7.1]
  def change
    add_reference :compliance_controls, :assignee, foreign_key: { to_table: :users }
    add_column :compliance_controls, :due_date, :date
  end
end
