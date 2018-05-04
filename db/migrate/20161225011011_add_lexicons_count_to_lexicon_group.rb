class AddLexiconsCountToLexiconGroup < ActiveRecord::Migration[5.0]
  def change
    add_column :lexicon_groups, :lexicons_count, :integer, default: 0
  end
end
