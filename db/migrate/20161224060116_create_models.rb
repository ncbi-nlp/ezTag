class CreateModels < ActiveRecord::Migration[5.0]
  def change
    create_table :models do |t|
      t.string :url
      t.references :user, foreign_key: true
      t.string :name

      t.timestamps
    end
    add_reference :tasks, :model, index: true, foreign_key: true
  end
end
