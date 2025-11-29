class AddTypeAndSuggestedTextToComments < ActiveRecord::Migration[7.1]
  def change
    add_column :comments, :comment_type, :string, default: 'comment'
    add_column :comments, :suggested_text, :text
  end
end
