class ChangeNameTypeInLexicon < ActiveRecord::Migration[5.0]
  def change
    change_column :lexicons, :name, :text
  end
end
