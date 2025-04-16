class ArtworksContainer
  def initialize(artworks)
    @artworks = artworks
  end

  # Explicitly defines the json structure
  def as_json(options = nil)
    { :artworks => @artworks }
  end

  def to_json(*a)
    as_json.to_json(*a)
  end
end
