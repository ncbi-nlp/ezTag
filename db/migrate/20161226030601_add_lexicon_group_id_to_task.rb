class AddLexiconGroupIdToTask < ActiveRecord::Migration[5.0]
  def change
    remove_reference :tasks, :lexicon, index: true, foreign_key: true
    add_reference :tasks, :lexicon_group, index: true, foreign_key: true
  end
end
