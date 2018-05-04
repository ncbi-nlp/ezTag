class DropUnnecessaryTables < ActiveRecord::Migration[5.0]
  def change
    drop_table :info_nodes
    drop_table :locations
    drop_table :nodes
    drop_table :annotations
    drop_table :relations
    drop_table :sentences
    drop_table :passages
  end
end
