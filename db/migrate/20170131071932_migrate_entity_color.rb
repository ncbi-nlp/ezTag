class MigrateEntityColor < ActiveRecord::Migration[5.0]
  def change
    EntityType.all.each do |e|
      e.color = "#" + e.color.upcase
      e.save
    end 
  end
end
