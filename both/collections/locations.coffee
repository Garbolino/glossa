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
  medias:
    type: [String]
    optional: true


Locations.attachSchema(LocationSchema)


Meteor.methods
  'getOrCreateLocation': (params) ->
    check(params, {name:String, lat:String, lng:String})
    slug = getSlug(name)
    location = Locations.findOne {slug: slug}
    if location
      return location._id

    params.slug = slug
    locationId = Locations.insert(params)
    locationId


