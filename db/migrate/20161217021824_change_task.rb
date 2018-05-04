class ChangeTask < ActiveRecord::Migration[5.0]
  def change
    remove_column :tasks, :begin_at
    remove_column :tasks, :end_at
    add_column :tasks, :tool_begin_at, :datetime
    add_column :tasks, :tool_end_at, :datetime
    add_column :tasks, :canceled_at, :datetime
  end
end
