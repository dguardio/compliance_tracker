class CreateRegulations < ActiveRecord::Migration[7.1]
  def change
    create_table :regulations do |t|
      t.string   :external_id, index: true # e.g., agency-specific ID
      t.string   :title, null: false
      t.string   :agency, null: false
      t.string   :jurisdiction, null: false
      t.string   :reg_type # e.g., rule, guidance, notice
      t.date     :effective_date
      t.date     :publication_date
      t.string   :status # e.g., active, amended, repealed
      t.integer  :version, default: 1
      t.references :previous_version, foreign_key: { to_table: :regulations }
      # JSONB fields for flexible storage
      t.jsonb    :full_text, default: {} # { main: "...", sections: {...} }
      t.jsonb    :files, default: {}     # { pdf: url, html: url, ... }
      t.jsonb    :metadata, default: {}  # { source_url: ..., tags: [...], ... }
      t.timestamps
    end
    add_index :regulations, %i[agency jurisdiction external_id version], unique: true
  end
end