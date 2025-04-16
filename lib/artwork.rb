class Artwork
  def initialize(name, extensions, link, image)
    @name = name
    @extensions = extensions
    @link = link
    @image = image
  end

  # Explicitly defines the json structure
  # Only output extensions if it has content
  def as_json(options = nil)
    if @extensions.length > 0
      { :name => @name, :extensions => @extensions, :link => @link, :image => @image }
    else
      { :name => @name, :link => @link, :image => @image }
    end

  end

  def to_json(*a)
    as_json.to_json(*a)
  end
end
