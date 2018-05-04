class User < ApplicationRecord
  has_many :collections, dependent: :destroy
  has_many :lexicon_groups, dependent: :destroy
  has_many :models,-> { order 'created_at desc' }, dependent: :destroy
  has_many :tasks, dependent: :destroy
  
  def self.new_user
    user = User.new
    user.session_str = SecureRandom.uuid
    user
  end

  def has_samples?
    self.collections.where("`key` = ?", 'samples').present?
  end

  def has_sample_lexicons?
    self.lexicon_groups.where("`key` = ?", 'samples').present?
  end
  def session_tail
    self.session_str[-12..-1] || self.session_str
  end 
end
