class AddDoneToDocument < ActiveRecord::Migration[5.0]
  def change
    add_column :documents, :done, :boolean, default: false
  end
end
