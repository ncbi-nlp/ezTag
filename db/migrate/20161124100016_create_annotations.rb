class CreateAnnotations < ActiveRecord::Migration[5.0]
  def change
    create_table :annotations do |t|
      t.references :document, foreign_key: true
      t.string :entity_type
      t.string :concept_id

      t.timestamps
    end
  end
end
