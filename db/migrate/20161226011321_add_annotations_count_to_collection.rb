class AddAnnotationsCountToCollection < ActiveRecord::Migration[5.0]
  def change
    add_column :collections, :annotations_count, :integer, default:0
    Collection.all.each do |c|
      c.update_annotation_count
    end
  end
end
