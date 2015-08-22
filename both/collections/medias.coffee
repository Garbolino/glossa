@Medias = new Mongo.Collection('medias')

Medias.allow
  insert: (userId, doc) ->
    # only allow posting if you are logged in
    true
  update: (userId, doc) ->
    # only allow posting if you are logged in
    true
  remove: (userId, doc) ->
    true

@MediaSchema = new SimpleSchema
  userId:
    label: 'userId'
    type: String
  title:
    label: 'title'
    type: String
  audioUrl:
    label: 'audioUrl'
    type: String
    optional: true
  videoUrl:
    label: 'videoUrl'
    type: String
    optional: true
  mediaType:
    label: 'mediaType'
    type: String
    allowedValues: ['audio', 'video']
  locationId:
    label: 'locationId'
    type: String
  createdAt:
    label: 'updatedAt'
    type: Date
    optional: true
  active:
    label: 'active'
    type: Boolean
    optional: true

Medias.attachSchema(MediaSchema)


Meteor.methods
  'createMedia': (params) ->
    check(params, {title:String, mediaType:String, locationId: String})

    userId = Meteor.userId()
    if !userId
      throw new Meteor.Error(401, "You need to login to post new audios")

    params.userId = userId
    params.createdAt = new Date()
    params.active = true

    mediaId = Medias.insert params
    mediaId


