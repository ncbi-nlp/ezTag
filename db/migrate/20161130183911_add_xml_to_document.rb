class AddXmlToDocument < ActiveRecord::Migration[5.0]
  def change
    add_column :documents, :xml, :text, :limit => 4294967295
  end
end
