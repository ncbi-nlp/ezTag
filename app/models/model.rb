class Model < ApplicationRecord
  belongs_to :user
  validates :name, presence: true
  has_many :task, dependent: :nullify
  
  def option_item
    ["[User] #{self.name} (created at #{self.created_at})", self.id]
  end

  def model_url
    "https://www.ncbi.nlm.nih.gov/CBBresearch/Lu/Demo/RESTful/eztag.cgi/ezTag_#{self.user.session_str}_#{self.url}"
  end
  def status
    if self.url.blank?
      "Processing"
    else
      "Done"
    end
  end
end
