class CreateTasks < ActiveRecord::Migration[5.0]
  def change
    create_table :tasks do |t|
      t.references :user, foreign_key: true
      t.references :collection, foreign_key: true
      t.string :tagger
      t.integer :task_type
      t.string :pre_trained_model
      t.string :status
      t.string :model_url, limit: 1000
      t.string :xml_url, limit: 1000
      t.datetime :begin_at
      t.datetime :end_at

      t.timestamps
    end
  end
end
