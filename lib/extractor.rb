require 'nokogiri'
require 'open-uri'
require 'json'
require './lib/artworks_container'
require './lib/artwork'

class Extractor
  def initialize(
    link_prefix:,
    artworks_class:,
    artwork_class:,
    name_class:,
    extensions_class:,
    skip_on_error: true
  )
    @link_prefix = link_prefix
    @artworks_class = artworks_class
    @artwork_class = artwork_class
    @name_class = name_class
    @extensions_class = extensions_class
    @skip_on_error = skip_on_error
  end

  # Extract the artwork gallery from input html and output it to a json file
  def extract(input_path, output_path)
    html = open(input_path)
    doc = Nokogiri::HTML(html)
    image_hash = extract_images(doc)

    artworks_xml_parent = get_div_by_class(doc, @artworks_class)
    if artworks_xml_parent.length == 0
      puts "No Artworks container found"
      return false
    end

    begin
      artworks = extract_artworks(artworks_xml_parent, image_hash)
      artworks_container = ArtworksContainer.new(artworks)
      File.write(output_path, JSON.pretty_generate(artworks_container))
    rescue => error
      puts error
      return false
    end

    true
  end

  # Extract images from the javascript variables and store them in a hash
  def extract_images(doc)
    image_hash = Hash.new
    scripts_xml = doc.xpath('//script')
    scripts_xml.each do |script_xml|
      script_content = script_xml.content
      if script_content.include?("_setImagesSrc(ii,s,r);")
        # Example format: var ii=['_L_FkZ4qlAtyDwbkP49Pj0QU_63'];
        key_matches = script_content.match(/var ii=\['([^']+)'\];/)
        if key_matches
          key = key_matches[1]
          # Example format: var s='data:image/jpeg;base64,etc';
          value_matches = script_content.match(/var s='([^']+)';/)
          if value_matches
            value = value_matches[1]
            # Not ideal, but this seems to be the only obfuscated character in the javascript strings. Revisit.
            value = value.gsub("\\x3d", "=")
            image_hash[key] = value
          end
        end
      end
    end
    image_hash
  end

  # Extract an array of Artwork objects from the parent xml
  def extract_artworks(artworks_xml_parent, image_hash)
    artworks = Array.new
    artworks_xml = get_div_by_class(artworks_xml_parent.first, @artwork_class)
    artworks_xml.each do |artwork_xml|
      begin
        artwork = extract_artwork(artwork_xml, image_hash)
        artworks.append(artwork)
      rescue => error
        if @skip_on_error
          # Keep going and ignore elements that are missing critical data
          next
        else
          # Raise an exception
          raise error
        end
      end
    end
    artworks
  end

  # Extract an Artwork object from the xml, using the image hash if necessary
  def extract_artwork(artwork_xml, image_hash)
    name = extract_artwork_name(artwork_xml)
    extensions = extract_artwork_extensions(artwork_xml)
    link = extract_artwork_link(artwork_xml)
    image = extract_artwork_image(artwork_xml, image_hash)

    Artwork.new(name, extensions, link, image)
  end

  # Extract artwork name, throwing an error if not present
  def extract_artwork_name(artwork_xml)
    name_xml = get_div_by_class(artwork_xml, @name_class)
    if name_xml.length == 0
      raise "Name not found"
    end
    name_xml.first.inner_html
  end

  # Extract artwork extensions. These are allowed to be absent.
  def extract_artwork_extensions(artwork_xml)
    extensions = Array.new
    extensions_xml = get_div_by_class(artwork_xml, @extensions_class)
    extensions_xml.each do |extension_xml|
      # Only add non-empty values
      year = extension_xml.inner_html.strip
      if year.length > 0
        extensions.append(year)
      end
    end
    extensions
  end

  # Extract artwork link, throwing an error if not present
  def extract_artwork_link(artwork_xml)
    link_xml = artwork_xml.xpath(".//a/@href")
    if link_xml.length == 0
      raise "Link not found"
    end

    "#{@link_prefix}#{link_xml.first}"
  end

  # Extract artwork image, using the image hash if necessary, throwing an error if not present
  def extract_artwork_image(artwork_xml, image_hash)
    image_xml = artwork_xml.xpath(".//img/@data-src")
    if image_xml.length == 0
      # Likely deferred data
      image_id_xml = artwork_xml.xpath(".//img/@id")
      if image_id_xml.length == 0
        raise "Image not found"
      else
        # Use the deferred image data from our javascript variables
        image_hash[image_id_xml.first.inner_html]
      end
    else
      image_xml.first
    end
  end

  # Finds xml in children based on div class name
  def get_div_by_class(xml, div_class)
    xml.xpath(".//div[@class='#{div_class}']")
  end
end
