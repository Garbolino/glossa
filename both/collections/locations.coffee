@Locations = new Mongo.Collection('locations')

@LocationSchema = new SimpleSchema
  name:
    type: String
  slug:
    type: String
  formatted_address:
    type: String
    optional: true
  lat:
    type: String
  lng:
    type: String
  locality:
    type: String
    max: 50
    optional: true
  country_short:
    type: String
    optional: true
  country:
    type: String
    optional: true


Locations.attachSchema(LocationSchema)

if Meteor.isServer
  Meteor.methods
    'getOrCreateLocation': (params) ->
      check(params, {name:String, slug: String, lat:String, lng:String, locality: String, country_short:String, country:String, formatted_address:String})

      userId = Meteor.userId()
      if !userId
        throw new Meteor.Error(401, "You need to login to create new locations")

      location = Locations.findOne {slug: params.slug}
      if location
        return location._id

      locationId = Locations.insert params
      locationId


