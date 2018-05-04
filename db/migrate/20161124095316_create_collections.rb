class CreateCollections < ActiveRecord::Migration[5.0]
  def change
    create_table :collections do |t|
      t.references :user, foreign_key: true
      t.string :name
      t.integer :documents_count, default: 0, null: false
      t.string :note
      t.string :source
      t.string :cdate
      t.string :key, index: true
      t.string :xml_url, limit: 1000
      t.string :mode_url, limit: 1000

      t.timestamps
    end
  end
end
