
Template.locationPage.onCreated ->
  @autorun =>
    @subscribe "locationMedias", @data.location._id


Template.locationPage.helpers
  'medias': () ->
    locationId = @location._id
    Medias.find({locationId:locationId}).fetch()

Template.mediaItem.helpers
  'isEditable': () ->
    userId = Meteor.userId()
    if userId is @_id then true else false

Template.mediaItem.events
  'click .play-recording': (e, t) ->
    $("#video_#{t.data._id}").get(0).play()
    $("#audio_#{t.data._id}").get(0).play()

  'click .stop-playing': (e, t) ->
    $("#video_#{t.data._id}").get(0).pause()
    $("#audio_#{t.data._id}").get(0).pause()
