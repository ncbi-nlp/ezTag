class CreateLexiconGroups < ActiveRecord::Migration[5.0]
  def change
    remove_reference :lexicons, :collection, index: true, foreign_key: true
    
    remove_column :collections, :mode_url

    add_reference :tasks, :lexicon, index: true, foreign_key: true

    remove_column :tasks, :model_url
    remove_column :tasks, :xml_url

    create_table :lexicon_groups do |t|
      t.string :name
      t.references :user, foreign_key: true

      t.timestamps
    end
    add_reference :lexicons, :lexicon_group, index: true, foreign_key: true    
  end
end
