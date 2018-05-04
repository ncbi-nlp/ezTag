class AddDidNoToDocument < ActiveRecord::Migration[5.0]
  def change
    Document.transaction do 
      add_column :documents, :did_no, :integer
      Document.all.each do |d|
        d.did_no = d.did.to_i
        d.save
      end
    end
  end
end
