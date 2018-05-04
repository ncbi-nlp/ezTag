class AddSentenceToInfoNode < ActiveRecord::Migration[5.0]
  def change
    add_reference :info_nodes, :sentence, foreign_key: true
  end
end
