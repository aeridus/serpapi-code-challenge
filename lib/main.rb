require './lib/extractor'

# All div class names are pulled from the example html
extractor = Extractor.new(
  link_prefix: "https://www.google.com",
  artworks_class: 'Cz5hV',
  artwork_class: 'iELo6',
  name_class: 'pgNMRc',
  extensions_class: 'cxzHyb',
  skip_on_error: true
)
extractor.extract("./files/van-gogh-paintings.html", "./files/actual-array.json")