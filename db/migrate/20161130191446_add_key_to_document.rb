class AddKeyToDocument < ActiveRecord::Migration[5.0]
  def change
    add_column :documents, :key, :string
  end
end
