class CreateInfoNodes < ActiveRecord::Migration[5.0]
  def change
    create_table :info_nodes do |t|
      t.string :key, limit: 1000
      t.string :value, limit: 1000
      t.references :collection, foreign_key: true
      t.references :document, foreign_key: true
      t.references :passage, foreign_key: true
      t.references :annotation, foreign_key: true

      t.timestamps
    end
  end
end
