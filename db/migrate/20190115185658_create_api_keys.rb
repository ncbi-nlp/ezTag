class CreateApiKeys < ActiveRecord::Migration[5.0]
  def change
    create_table :api_keys do |t|
      t.string :key,  :limit => 50
      t.references :user, foreign_key: true
      t.datetime   :last_access_at
      t.string     :last_access_ip
      t.integer    :access_count, default: 0, null: false
      t.timestamps
    end
    add_index :api_keys, :key, unique: true
  end
end
