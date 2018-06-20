class DeleteSpamUsers < ActiveRecord::Migration[5.0]
  def change
    User.all.each do |u|
      next if u.collections.size > 0
      u.destroy      
    end
  end
end
