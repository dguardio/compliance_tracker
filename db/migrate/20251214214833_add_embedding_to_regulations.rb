class AddEmbeddingToRegulations < ActiveRecord::Migration[7.1]
  def change

    # Use generic column definition to ensure compatibility
    add_column :regulations, :embedding, "vector(768)"
    
    add_index :regulations, :embedding, using: :hnsw, opclass: :vector_l2_ops
  end
end
