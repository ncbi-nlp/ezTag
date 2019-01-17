class EntityType < ApplicationRecord
  belongs_to :collection
  before_validation :normalize_name
  before_save :adjust_color
  validates :name, uniqueness: { scope: :collection, message: "- The type already exists in the collection" }
  validates :name, presence: { message: "- Invalid entity type"}
  COLORS = %w(#CCFFFF #CCFFCC #FFFF99 #FFCCCC #66CCFF #99FF66 #FFCC00 #CCFF66 #FF66FF #FF9999 #99CC00 #00CC99 #00CCFF #9966FF #CCCC00 #FF9933)

  DEFAULT_COLORMAP = {
    "chemical"  => "#CCFFFF",
    "gene"      => "#FFFF99",
    "disease"   => "#00CC99",
    "protein"   => "#99FF66"
  }
  def font_color
    a = ( self.color.match /(..?)(..?)(..?)/ )[1..3]
    a.map!{ |x| x + x } if self.color.size == 3

    r = a[0].hex
    g = a[1].hex
    b = a[2].hex
    g = (r + g + b) / 3.0
    Rails.logger.debug("== HEX #{self.color} r#{r} g#{g} b#{b} g#{g} =============")
    if g > 128
      return "000"
    else
      return "FFF"
    end
  end

  def normalize_name
    self.name = self.name.strip.tr(" \t\r\n", '_').gsub(/[^0-9a-zA-Z_]/i, '')
  end

  def adjust_color
    if self.color.blank?
      name = self.name.strip.downcase
      self.color = DEFAULT_COLORMAP[name]
      self.color = EntityType.random_color if self.color.blank?
    end
  end

  def self.random_color
    while true
      r = rand(256)
      g = rand(256)
      b = rand(256)
      gray = (r + g + b).to_f / 3.0
      break if gray > 160
    end
    "##{"%02X" % r}#{"%02X" % g}#{"%02X" % b}"
  end
end
