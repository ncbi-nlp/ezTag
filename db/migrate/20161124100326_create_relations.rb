class CreateRelations < ActiveRecord::Migration[5.0]
  def change
    create_table :relations do |t|
      t.references :document, foreign_key: true
      t.string :rid

      t.timestamps
    end
  end
end
