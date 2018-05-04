class AddBatchCreatedAtToDocument < ActiveRecord::Migration[5.0]
  def change
    add_column :documents, :batch_id, :integer, default: 0
    add_column :documents, :batch_no, :integer, default: 0
  end
end
