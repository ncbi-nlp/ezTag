class CreateLexicons < ActiveRecord::Migration[5.0]
  def change
    create_table :lexicons do |t|
      t.string :ltype
      t.string :lexicon_id, index: true
      t.string :name
      t.references :collection, foreign_key: true

      t.timestamps
    end
  end
end
