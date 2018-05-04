class CreatePassages < ActiveRecord::Migration[5.0]
  def change
    create_table :passages do |t|
      t.references :document, foreign_key: true
      t.integer :offset
      t.text :content

      t.timestamps
    end
  end
end
