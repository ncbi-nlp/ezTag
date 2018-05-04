class CreateNodes < ActiveRecord::Migration[5.0]
  def change
    create_table :nodes do |t|
      t.references :relation, foreign_key: true
      t.string :refid
      t.string :role

      t.timestamps
    end
  end
end
