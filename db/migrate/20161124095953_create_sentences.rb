class CreateSentences < ActiveRecord::Migration[5.0]
  def change
    create_table :sentences do |t|
      t.references :passage, foreign_key: true
      t.integer :offset
      t.text :content

      t.timestamps
    end
  end
end
