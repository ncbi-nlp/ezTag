class ChangeDefaultForDocumentCuratable < ActiveRecord::Migration[5.0]
  def change
    change_column_default(:documents, :curatable, true)
  end
end
