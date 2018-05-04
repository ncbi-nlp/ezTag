class CreateLocations < ActiveRecord::Migration[5.0]
  def change
    create_table :locations do |t|
      t.references :annotation, foreign_key: true
      t.integer :offset
      t.integer :length

      t.timestamps
    end
  end
end
