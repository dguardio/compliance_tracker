class ResizeEmbeddingColumnTo768 < ActiveRecord::Migration[7.1]
  def up
    remove_index :standard_requirements, :embedding
    execute "ALTER TABLE standard_requirements ALTER COLUMN embedding TYPE vector(768);"
    add_index :standard_requirements, :embedding, using: :hnsw, opclass: :vector_l2_ops
  end

  def down
    remove_index :standard_requirements, :embedding
    execute "ALTER TABLE standard_requirements ALTER COLUMN embedding TYPE vector(1536);"
    add_index :standard_requirements, :embedding, using: :hnsw, opclass: :vector_l2_ops
  end
end
