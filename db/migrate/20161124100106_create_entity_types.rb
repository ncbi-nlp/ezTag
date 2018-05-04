class CreateEntityTypes < ActiveRecord::Migration[5.0]
  def change
    create_table :entity_types do |t|
      t.references :collection, foreign_key: true
      t.string :name
      t.string :color

      t.timestamps
    end
  end
end
