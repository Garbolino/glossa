Meteor.publish 'locations', ->
  Locations.find()

Meteor.publish 'location', (slug) ->
  Locations.find({slug:slug})

Meteor.publish 'locationMedias', (locationId) ->
  Medias.find({locationId:locationId}, {sort:{'createdAt':-1}})
