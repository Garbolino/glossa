Meteor.publish 'locations', ->
  Locations.find()

Meteor.publish 'location', (slug) ->
  Locations.find({slug:slug})
