class AddCuratbleToDocument < ActiveRecord::Migration[5.0]
  def change
    add_column :documents, :curatable, :boolean, default: false
  end
end
