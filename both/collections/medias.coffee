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

MediaSchema = new SimpleSchema
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
  recorderBy:
    label: 'recorderBy'
    type: String
    allowedValues: ['browser', 'file', 'cordova']
  locationId:
    label: 'locationId'
    type: String
    optional: true
  locationSlug:
    label: 'locationSlug'
    type: String
    optional: true
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
    userId = Meteor.userId()
    if !userId
      throw new Meteor.Error(401, "You need to login to post new audios")

    media = params.media
    if !media.audioUrl and !media.videoUrl
      throw new Meteor.Error(403, "There is not uploaded media")

    if !params.location.name
      throw new Meteor.Error(403, "There is not location for this media")

    media.userId = userId
    media.createdAt = new Date()
    media.active = true

    mediaId = Medias.insert media
    Meteor.call 'getOrCreateLocation', params.location, (error, locationId) ->
      if error
        console.log(error)
      else
        updateMedia =
          $set:
            'locationId': locationId
            'locationSlug': params.location.slug
        Medias.update({_id: mediaId}, updateMedia)

    params.location.slug


