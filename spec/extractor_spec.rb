require 'rspec'
require './lib/extractor'

def init_extractor(skip_on_error)
  Extractor.new(
    link_prefix: "https://www.google.com",
    artworks_class: 'Cz5hV',
    artwork_class: 'iELo6',
    name_class: 'pgNMRc',
    extensions_class: 'cxzHyb',
    skip_on_error: skip_on_error
  )
end

describe Extractor do
  it "should have an empty hash when we call the extract_image_from_script method with an irrelevant script" do
    extractor = init_extractor(true)

    image_hash = Hash.new
    extractor.extract_image_from_script(image_hash, "test")

    expect(image_hash.length).to eq 0
  end

  it "should have a populated hash when we call the extract_image_from_script method with a relevant script" do
    extractor = init_extractor(true)

    image_hash = Hash.new
    extractor.extract_image_from_script(
      image_hash,
      "_setImagesSrc(ii,s,r);var ii=['test'];var s='output\\x3d';"
    )

    expect(image_hash["test"]).to eq "output="
  end

  it "should have a name when we call the extract_artwork_name method with valid xml" do
    extractor = init_extractor(true)

    doc = Nokogiri::HTML("<div class=\"pgNMRc\">Hello</div>")
    name = extractor.extract_artwork_name(doc)

    expect(name).to eq "Hello"
  end

  it "should raise an exception when we call the extract_image_from_script method with invalid xml" do
    extractor = init_extractor(true)

    doc = Nokogiri::HTML("<div class=\"test\">Hello</div>")
    expect { extractor.extract_artwork_name(doc) }.to raise_error(message = "Name not found")
  end

  it "should have an extension when we call the extract_artwork_extensions method with valid xml" do
    extractor = init_extractor(true)

    doc = Nokogiri::HTML("<div class=\"cxzHyb\">Hello</div>")
    extensions = extractor.extract_artwork_extensions(doc)

    expect(extensions[0]).to eq "Hello"
  end

  it "should return an empty array when we call the extract_artwork_extensions method with empty xml" do
    extractor = init_extractor(true)

    doc = Nokogiri::HTML("<div class=\"cxzHyb\"></div>")
    extensions = extractor.extract_artwork_extensions(doc)

    expect(extensions.length).to eq 0
  end

  it "should return an empty array when we call the extract_artwork_extensions method with invalid xml" do
    extractor = init_extractor(true)

    doc = Nokogiri::HTML("<div class=\"Test\">1989</div>")
    extensions = extractor.extract_artwork_extensions(doc)

    expect(extensions.length).to eq 0
  end

  it "should have a link when we call the extract_artwork_link method with valid xml" do
    extractor = init_extractor(true)

    doc = Nokogiri::HTML("<a href=\"/index.html\">Test</div>")
    link = extractor.extract_artwork_link(doc)

    expect(link).to eq "https://www.google.com/index.html"
  end

  it "should raise an exception when we call the extract_artwork_link method with invalid xml" do
    extractor = init_extractor(true)

    doc = Nokogiri::HTML("<a>Test</a>")
    expect { extractor.extract_artwork_link(doc) }.to raise_error(message = "Link not found")
  end

  it "should have an image when we call the extract_artwork_image method with valid xml" do
    extractor = init_extractor(true)

    doc = Nokogiri::HTML("<div><img data-src=\"ok.jpg\" src=\"temp.jpg\"></div>")
    image_hash = Hash.new
    image = extractor.extract_artwork_image(doc, image_hash)

    expect(image).to eq "ok.jpg"
  end

  it "should have a deferred image when we call the extract_artwork_image method with valid xml" do
    extractor = init_extractor(true)

    doc = Nokogiri::HTML("<div><img id=\"test\" src=\"temp.jpg\"></div>")
    image_hash = Hash.new
    image_hash["test"] = "base64"
    image = extractor.extract_artwork_image(doc, image_hash)

    expect(image).to eq "base64"
  end

  it "should raise an exception when we call the extract_artwork_image method with invalid xml" do
    extractor = init_extractor(true)

    doc = Nokogiri::HTML("<div><img id=\"/test\" src=\"temp.jpg\"></div>")
    image_hash = Hash.new
    expect { extractor.extract_artwork_image(doc, image_hash) }.to raise_error(message = "Image not found")
  end

  it "should raise an exception when we call the extract_artwork_image method with empty xml" do
    extractor = init_extractor(true)

    doc = Nokogiri::HTML("<div></div>")
    image_hash = Hash.new
    expect { extractor.extract_artwork_image(doc, image_hash) }.to raise_error(message = "Image not found")
  end
end