class AddOrderNoToCollection < ActiveRecord::Migration[5.0]
  def change
    add_column :collections, :order_no, :integer
    add_column :documents, :order_no, :integer
    add_index :collections, [:user_id, :order_no]
    add_index :documents, [:collection_id, :order_no]

    Collection.transaction do
      User.all.each do |u|
        c_no = u.collections.size
        u.collections.all.each do |c|
          c.order_no = c_no
          c.save!
          c_no -= 1
          d_no = c.documents.size
          c.documents.order("batch_id DESC, batch_no ASC, id DESC").each do |d|
            d.order_no = d_no
            d.save!
            d_no -= 1
          end
        end
      end
    end

  end
end
