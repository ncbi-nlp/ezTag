class AddKeyToLexiconGroup < ActiveRecord::Migration[5.0]
  def change
    add_column :lexicon_groups, :key, :string, limit: 100
    add_index :lexicon_groups, :key
  end
end
