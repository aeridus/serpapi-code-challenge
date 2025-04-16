require 'nokogiri'
require 'open-uri'
require 'json'
require_relative './artworks_container'
require_relative './artwork'

class Extractor
  def initialize(
    artworks_class:,
    artwork_class:,
    name_class:,
    extensions_class:,
    skip_on_error: true
  )
    @artworks_class = artworks_class
    @artwork_class = artwork_class
    @name_class = name_class
    @extensions_class = extensions_class
    @skip_on_error = skip_on_error
  end

  def extract(input_path, output_path)
    html = open(input_path)
    doc = Nokogiri::HTML(html)
    image_hash = extract_images(doc)

    artworks_xml_parent = get_div_by_class(doc, @artworks_class)
    if artworks_xml_parent.length == 0
      puts "No Artworks container found"
      return
    end

    artworks = Array.new
    artworks_xml = get_div_by_class(artworks_xml_parent.first, @artwork_class)
    artworks_xml.each do |artwork_xml|
      artwork = parse_artwork_xml(artwork_xml, image_hash)

      if artwork == nil
        if @skip_on_error
          next
        else
          puts "Malformed artwork found"
          return
        end
      end

      artworks.append(artwork)
    end

    artworks_container = ArtworksContainer.new(artworks)
    File.write(output_path, JSON.pretty_generate(artworks_container))
  end

  def extract_images(doc)
    image_hash = Hash.new
    scripts_xml = doc.xpath('//script')
    scripts_xml.each do |script_xml|
      script_content = script_xml.content
      if script_content.include?("_setImagesSrc(ii,s,r);")
        key_matches = script_content.match(/var ii=\['([^']+)'\];/)
        if key_matches
          key = key_matches[1]
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

  def parse_artwork_xml(artwork_xml, image_hash)
    name_xml = get_div_by_class(artwork_xml, @name_class)
    if name_xml.length == 0
      return nil
    end
    name = name_xml.first.inner_html

    extensions = Array.new
    extensions_xml = get_div_by_class(artwork_xml, @extensions_class)
    extensions_xml.each do |extension_xml|
      # Only add non-empty values
      year = extension_xml.inner_html.strip
      if year.length > 0
        extensions.append(year)
      end
    end

    link_xml = artwork_xml.xpath(".//a/@href")
    if link_xml.length == 0
      return nil
    end
    link = "https://www.google.com#{link_xml.first}"

    image = ""
    image_xml = artwork_xml.xpath(".//img/@data-src")
    if image_xml.length == 0
      # Likely deferred data
      image_id_xml = artwork_xml.xpath(".//img/@id")
      if image_id_xml.length == 0
        return nil
      else
        image = image_hash[image_id_xml.first.inner_html]
      end
    else
      image = image_xml.first
    end

    Artwork.new(name, extensions, link, image)
  end

  def get_div_by_class(xml, div_class)
    xml.xpath(".//div[@class='#{div_class}']")
  end
end
