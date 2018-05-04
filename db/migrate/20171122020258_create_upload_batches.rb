class CreateUploadBatches < ActiveRecord::Migration[5.0]
  def change
    create_table :upload_batches do |t|

      t.timestamps
    end
  end
end
