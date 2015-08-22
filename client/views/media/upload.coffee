allowedFileTypes = ["audio/wav", "audio/3gpp"]
@audioFile = null
@videoFile = null

validateMedia = (params) ->
  errors = {}
  errors.location = "Please select a location"  unless params.location
  errors.title = "Please fill audio title"  unless params.title
  errors.mediaFile = "Please record audio or video"  unless params.mediaFile
  errors

validateMediaType = (mediaFile) ->
  errors = {}
  mediaType = mediaFile.type
  if not mediaType in allowedFileTypes
    errors.mediaFile = "Wrong media format"
  errors

Template.uploadMedia.helpers
  'errorMessage': (field) ->
    errors = Session.get("mediaSubmitErrors")
    if errors
      errors[field]

  'errorClass': (field) ->
    if !!Session.get("mediaSubmitErrors")[field] then "has-error" else ""

  'isCordova':()->
    Meteor.isCordova

Template.uploadMedia.onCreated ->
  Session.set 'mediaSubmitErrors', {}

Template.uploadMedia.onRendered ->
  $('.recordWeb').hide()
  Session.set 'supportsMedia', false
  @autorun ->
    if GoogleMaps.loaded()
      $('#geocomplete').geocomplete(
        details: ".details"
        types: ['(cities)']
        detailsAttribute: "data-geo"
      )
    return
  return


Template.uploadMedia.events
  'click .record': (e, t) ->
    e.preventDefault()
    mediaType = $(e.target).data('media')
    Session.set 'supportsMedia', supportsMedia()
    Session.set 'mediaType', mediaType
    $('.recordWeb').fadeIn()
    return

  'submit #uploadMediaForm': (e, t) ->
    e.preventDefault()
    $('#submitMedia').attr("disabled", true)
    hasMediaFile = null
    location = $(e.target).find("[name=location]").val()
    title = $(e.target).find("[name=title]").val()
    mediaFile = $(e.target).find("[name=mediaFile]").val()
    if !mediaFile
      audioFile = Session.get 'audioFile'
      videoFile = Session.get 'videoFile'
      if audioFile
        hasMediaFile = true
    else
      hasMediaFile = true

    mediaParams =
      location: location
      title: title
      mediaFile: hasMediaFile

    address =
      name: location
      lat: $(e.target).find("[name=lat]").val()
      lng: $(e.target).find("[name=lng]").val()
      formatted_address: $(e.target).find("[name=formatted_address]").val()
      country_short: $(e.target).find("[name=country_short]").val()
      country: $(e.target).find("[name=country]").val()
      locality: $(e.target).find("[name=locality]").val()

    errors = validateMedia(mediaParams)
    if Object.keys(errors).length isnt 0
      $('#submitMedia').attr("disabled", false).html('Submit')
      return Session.set "mediaSubmitErrors", errors

    if mediaFile
      errors = validateMediaType(mediaFile)
      if Object.keys(errors).length isnt 0
        $('#submitMedia').attr("disabled", false).html('Submit')
        return Session.set "mediaSubmitErrors", errors
      #send mediaFile

    if videoFile
      errors = validateMediaType(audioFile)
      errors = validateMediaType(videoFile)
      if Object.keys(errors).length isnt 0
        $('#submitMedia').attr("disabled", false).html('Submit')
        return Session.set "mediaSubmitErrors", errors
      #send audioBlob and videoBlob

    else
      errors = validateMediaType(audioFile)
      if Object.keys(errors).length isnt 0
        $('#submitMedia').attr("disabled", false).html('Submit')
        return Session.set "mediaSubmitErrors", errors

      #send audioBlob
      uploader.send audioBlob, (error, downloadUrl) ->
        if error
          # Log service detailed response.
          console.error 'Error uploading'
          alert error
        else
          #create media with location and downloadUrl
          Meteor.call 'getOrCreateLocation', address, (error, data) ->
            if error
              console.log(error)
            else
              params =
                title: title
                audioUrl: downloadUrl
                mediaType: 'audio'
                locationId: locationId
              Meteor.call 'createMedia', params
        return
