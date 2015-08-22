Meteor.startup ->
  GoogleMaps.load(
    libraries: 'places'
  )
  return
