metaContext =
  mediaType: null
  recorderBy: null
@uploader = new (Slingshot.Upload)('myFileUploads', metaContext)

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
  $('.wrapper').addClass('home')
  $('#progressUpload').hide()
  Session.set 'supportsMedia', false
  @autorun ->
    if GoogleMaps.loaded()
      $('#geocomplete').geocomplete(
        details: ".details"
        types: ['(cities)']
        componentRestrictions: {'country': "ph"}
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
    Session.set 'supportsMedia', false
    $('#submitMedia').attr("disabled", true).html("<i class='fa fa-spinner fa-spin'></i> Processing...")
    hasMediaFile = null
    location = $(e.target).find("[name=location]").val()
    title = $(e.target).find("[name=title]").val()
    mediaFile = $(e.target).find("[name=mediaFile]").val()
    $('#progressUpload').show()
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
      slug: getSlug(location)
      lat: $(e.target).find("[name=lat]").val()
      lng: $(e.target).find("[name=lng]").val()
      formatted_address: $(e.target).find("[name=formatted_address]").val()
      country_short: $(e.target).find("[name=country_short]").val()
      country: $(e.target).find("[name=country]").val()
      locality: $(e.target).find("[name=locality]").val()
    now = new Date().getTime()
    filename = moment(new Date(now)).format("H:mm:ss-DD-MM-YY") + '--' + getSlug(title)

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
      metaContext.mediaType = 'video'
      metaContext.recorderBy = 'browser'
      audioBlob.name = "audio-#{filename}"
      videoBlob.name = "video-#{filename}"
      uploader.send audioBlob, (error, audioUrl) ->
        if error
          # Log service detailed response.
          console.error 'Error uploading'
          $('#progressUpload').hide()
          sAlert.error(error)
        else
          audioUrl = audioUrl
          uploader.send videoBlob, (error, videoUrl) ->
            if error
              # Log service detailed response.
              console.error 'Error uploading'
              $('#progressUpload').hide()
              sAlert.error(error)
            else
                media =
                  title: title
                  audioUrl: audioUrl
                  videoUrl: videoUrl
                  mediaType: 'video'
                  recorderBy: 'browser'
                params =
                  location: address
                  media: media

                Meteor.call 'createMedia', params, (error, locationSlug) ->
                  if error
                    console.log(error)
                  else
                    Router.go 'locationPage', {slug:locationSlug}
            return
          return
      return
    else
      errors = validateMediaType(audioFile)
      if Object.keys(errors).length isnt 0
        $('#submitMedia').attr("disabled", false).html('Submit')
        return Session.set "mediaSubmitErrors", errors

      #send audioBlob
      metaContext.mediaType = 'audio'
      metaContext.recorderBy = 'browser'
      audioBlob.name = "audio-#{filename}"
      uploader.send audioBlob, (error, downloadUrl) ->
        if error
          # Log service detailed response.
          console.error 'Error uploading'
          $('#progressUpload').hide()
          sAlert.error(error)
        else
          $('#progressUpload').hide()
          #create media with location and downloadUrl
          media =
            title: title
            audioUrl: downloadUrl
            mediaType: 'audio'
            recorderBy: 'browser'
          params =
            location: address
            media: media

          Meteor.call 'createMedia', params, (error, locationSlug) ->
            if error
              console.log(error)
            else
              Router.go 'locationPage', {slug:locationSlug}
        return
