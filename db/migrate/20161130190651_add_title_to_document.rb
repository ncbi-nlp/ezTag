class AddTitleToDocument < ActiveRecord::Migration[5.0]
  def change
    add_column :documents, :title, :text
  end
end
