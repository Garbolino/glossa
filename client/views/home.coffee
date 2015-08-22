markers = {}

getInfoWindow = (slug,name) ->
  contentString = "<a href='/accents/#{slug}' id='content'>#{name}</a>"
  contentString


Template.homePage.onCreated ->
  self = @
  self.selectedMarkerId = new (Blaze.ReactiveVar)(null)
  # We can use the `ready` callback to interact with the map API once the map is ready.

  GoogleMaps.ready 'mediaMap', (map) ->

    self.infowindow = new (google.maps.InfoWindow)(content: '')
    self.gmap = map.instance
    google.maps.event.addListener self.infowindow, 'closeclick', ->
      if self.selectedMarkerId.get()
        self.selectedMarkerId.set null
      return

    self.autorun ->
      if self.selectedMarkerId.get()
        marker = markers[self.selectedMarkerId.get()]
        if marker
          self.infowindow.setContent(marker.infoWindowContent)
          self.infowindow.open(self.gmap, marker)

    # Add a marker to the map once it's ready
    Locations.find().observe
      added: (document) ->
        # Create a marker for this document
        marker = new (google.maps.Marker)(
          animation: google.maps.Animation.DROP
          position: new (google.maps.LatLng)(document.lat, document.lng)
          map: map.instance
          title: document.title
          infoWindowContent: getInfoWindow(document.slug, document.name)
          id: document._id)

        google.maps.event.addListener marker, 'click', (event) ->
          self.selectedMarkerId.set document._id

        markers[document._id] = marker
        return
      changed: (newDocument, oldDocument) ->
        markers[newDocument._id].setPosition
          lat: newDocument.lat
          lng: newDocument.lng
        return
      removed: (oldDocument) ->
        # Remove the marker from the map
        markers[oldDocument._id].setMap null
        # Clear the event listener
        google.maps.event.clearInstanceListeners markers[oldDocument._id]
        # Remove the reference to this marker instance
        delete markers[oldDocument._id]
        return
  return

Template.homePage.onRendered ->

  # @autorun ->
  #   userLoc = Geolocation.latLng()
  #   if userLoc
  #     Session.set('geoLocation', userLoc)


Template.homePage.helpers
  mapOptions: ->
    # return 0, 0 if the location isn't ready
    if GoogleMaps.loaded()
      lat = 13
      lng = 122
      return {
          center: new google.maps.LatLng(lat, lng),
          zoom: 5
        }
    return

  mapReady: ->
    return !!GoogleMaps.loaded()

Template.homePage.events
 'click #logout': (e) ->
    e.preventDefault()
    Meteor.logout((error)->
      if error
        console.log(error)
      else
        console.log('logout')
        Router.go 'homePage'
    )


