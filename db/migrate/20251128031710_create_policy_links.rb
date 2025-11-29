class CreatePolicyLinks < ActiveRecord::Migration[7.1]
  def change
    create_table :policy_links do |t|
      t.references :policy, null: false, foreign_key: true
      t.references :linkable, polymorphic: true, null: false
      t.string :citation
      t.text :notes

      t.timestamps
    end
  end
end
