Meteor.startup ->
  GoogleMaps.load(
    libraries: 'places'
    language: 'en'
    types: '(cities)'
  )
  return
