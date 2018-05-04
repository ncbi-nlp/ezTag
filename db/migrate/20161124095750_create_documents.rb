class CreateDocuments < ActiveRecord::Migration[5.0]
  def change
    create_table :documents do |t|
      t.references :collection, foreign_key: true
      t.string :did, index: true
      t.datetime :user_updated_at
      t.datetime :tool_updated_at
      t.integer :annotations_count, default: 0, null: false

      t.timestamps
    end
  end
end
