class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  before_validation :generate_session_str
  has_many :api_keys, dependent: :destroy

  def generate_session_str
    self.session_str = SecureRandom.uuid if self.session_str.blank?
  end

  def super_admin?
    self.super_admin
  end

  has_many :collections, dependent: :destroy
  has_many :lexicon_groups, dependent: :destroy
  has_many :models,-> { order 'created_at desc' }, dependent: :destroy
  has_many :tasks, dependent: :destroy
  
  def self.new_user
    user = User.new
    user.session_str = SecureRandom.uuid
    user.email = SecureRandom.uuid + '@not-exist.email'
    user.password = 'invalid_password'
    user
  end

  def valid_email?
    self.email.present? && !self.email.include?('@not-exist.email') 
  end

  def email_or_id
    return self.email if self.email.present?
    "User#{self.id}"
  end
  def has_samples?
    self.collections.where("`key` = ?", 'samples').present?
  end

  def has_sample_lexicons?
    self.lexicon_groups.where("`key` = ?", 'samples').present?
  end

  def session_tail
    if self.session_str.blank?
      self.session_str = SecureRandom.uuid
      self.save!
    end
    self.session_str[-12..-1] || self.session_str
  end 

  def session_short
    if self.session_str.blank?
      self.session_str = SecureRandom.uuid
      self.save!
    end
    "#{self.session_str[0...4]}...#{self.session_str[-6...-1]}" || self.session_str
  end
end
