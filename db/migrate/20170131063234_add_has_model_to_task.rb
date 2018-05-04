class AddHasModelToTask < ActiveRecord::Migration[5.0]
  def change
    add_column :tasks, :has_model, :boolean, default: false
    add_column :tasks, :has_lexicon_group, :boolean, default: false

    Task.all.each do |t|
      t.has_lexicon_group = true unless t.lexicon_group_id.nil?
      t.has_model = true unless t.model_id.nil?
      t.save
    end
  end
end
