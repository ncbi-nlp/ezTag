class AddStatusToCollection < ActiveRecord::Migration[5.0]
  def change
    add_column :collections, :status, :string
  end
end
