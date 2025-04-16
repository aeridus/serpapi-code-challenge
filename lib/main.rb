require_relative './extractor'

extractor = Extractor.new(
  artworks_class: 'Cz5hV',
  artwork_class: 'iELo6',
  name_class: 'pgNMRc',
  extensions_class: 'cxzHyb',
  skip_on_error: true
)
extractor.extract("./files/van-gogh-paintings.html", "./files/actual-array.json")