navigator.getUserMedia = navigator.getUserMedia or navigator.webkitGetUserMedia or navigator.mozGetUserMedia or navigator.msGetUserMedia
window.URL = window.URL or window.webkitURL
window.requestAnimationFrame = do ->
  window.requestAnimationFrame or window.webkitRequestAnimationFrame or window.mozRequestAnimationFrame or window.oRequestAnimationFrame or window.msRequestAnimationFrame
window.AudioContext = window.AudioContext or window.webkitAudioContext
mediaStream = undefined
# global variables for showing/encoding the video
mediaInitialized = false
recording = false
videoCanvas = undefined
videoContext = undefined
frameTime = undefined
imageArray = []
# global variables for recording audio
audioContext = undefined
audioRecorder = undefined
# exposed template helpers
# cross-browser support for getUserMedia

@supportsMedia = ->
  !!(navigator.getUserMedia or navigator.webkitGetUserMedia or navigator.mozGetUserMedia or navigator.msGetUserMedia)

# function for requesting the media stream

setupMedia = (mediaRequired) ->
  if supportsMedia()
    audioContext = new AudioContext
    navigator.getUserMedia mediaRequired, ((localMediaStream) ->

      if mediaRequired.video
        # map the camera
        video = document.getElementById('live_video')
        video.src = window.URL.createObjectURL(localMediaStream)
        # create the canvas & get a 2d context
        videoCanvas = document.createElement('canvas')
        videoContext = videoCanvas.getContext('2d')
      # setup audio recorder
      audioInput = audioContext.createMediaStreamSource(localMediaStream)
      #audioInput.connect(audioContext.destination);
      # had to replace the above with the following to mute playback
      # (so you don't get feedback)
      audioGain = audioContext.createGain()
      audioGain.gain.value = 0
      audioInput.connect audioGain
      audioGain.connect audioContext.destination
      audioRecorder = new Recorder(audioInput)
      mediaStream = localMediaStream
      mediaInitialized = true
      document.getElementById('uploading').hidden = true
      document.getElementById('media-error').hidden = true
      document.getElementById('record').hidden = false
      return
    ), (e) ->
      console.log 'web-cam & microphone not initialized: ', e
      document.getElementById('media-error').hidden = false
      return
  return

startRecording = (mediaType) ->
  console.log 'Begin Recording'
  recording = true
  if mediaType is 'video'
    videoElement = document.getElementById('live_video')
    videoCanvas.width = videoElement.width
    videoCanvas.height = videoElement.height
    imageArray = []
    # do request frames until the user stops recording
    frameTime = (new Date).getTime()
    requestAnimationFrame recordFrame
  # begin recording audio
  audioRecorder.record()
  return

stopRecording = (mediaType) ->
  console.log 'End Recording'
  recording = false
  if mediaType is 'audio'
    document.getElementById('record').hidden = true
    completeRecording(mediaType)
  return

completeRecording = (mediaType = null)->
  # stop & export the recorder audio
  audioRecorder.stop()
  # user = Meteor.user()
  # if !user
  #   # must be the logged in user
  #   console.log 'completeRecording - NO USER LOGGED IN'
  #   return
  console.log 'completeRecording: '
  document.getElementById('uploading').hidden = false
  audioRecorder.exportWAV (audioBlob) =>
    # save to the db
    @audioBlob = audioBlob
    # Session.set 'audioFile', audioBlob
    BinaryFileReader.read audioBlob, (err, fileInfo) ->
      Session.set 'audioFile', fileInfo
      return
    console.log 'Audio uploaded'
    return

  if mediaType is 'audio'
    mediaStream.stop()
    return true
  # do the video encoding
  # note: tried doing this in real-time as the frames were requested but
  # the result didn't handle durations correctly.
  whammyEncoder = new (Whammy.Video)
  for i of imageArray
    `i = i`
    videoContext.putImageData imageArray[i].image, 0, 0
    whammyEncoder.add videoContext, imageArray[i].duration
    delete imageArray[i]
  @videoBlob = whammyEncoder.compile()

  BinaryFileReader.read videoBlob, (err, fileInfo) ->
    Session.set 'videoFile', fileInfo
    return
  console.log 'Video uploaded'
  # stop the stream & redirect to show the video
  mediaStream.stop()
  # Router.go 'showVideo', _id: user._id
  return

recordFrame = ->
  #    console.log("-frame");
  if recording
    image = undefined
    # draw the video to the context, then get the image data
    video = document.getElementById('live_video')
    width = video.width
    height = video.height
    videoContext.drawImage video, 0, 0, width, height
    # optionally get the image, do some filtering on it, then
    # put it back to the context
    imageData = videoContext.getImageData(0, 0, width, height)
    # - do some filtering on imageData
    videoContext.putImageData imageData, 0, 0
    frameDuration = (new Date).getTime() - frameTime
    console.log 'duration: ' + frameDuration
    #whammyEncoder.add(videoContext, frameDuration);
    imageArray.push
      duration: frameDuration
      image: imageData
    frameTime = (new Date).getTime()
    # request another frame
    requestAnimationFrame recordFrame
  else
    completeRecording()
  return

Template.recordWeb.onRendered ->
  Session.set 'audioFile', null
  Session.set 'videoFile', null

Template.recordWeb.helpers
  'onLoad': () ->
    mediaType = Session.get 'mediaType'
    if mediaType is 'audio'
      mediaRequired =
        audio: true
        video: false
    else
      mediaRequired =
        audio: true
        video: true
    setupMedia(mediaRequired)

  'mediaType': () ->
    Session.get 'mediaType'

  'supportsMedia': () ->
    Session.get 'supportsMedia'

  'recorded': () ->
    if Session.get 'videoFile' or Session.get 'audioFile' then true else false

  'videoFile': () ->
    video = Session.get 'videoFile'
    if video
      blob = new Blob([ video.file ], type: video.type)
      return window.URL.createObjectURL blob
    else
      null

  'audioFile': () ->
    audio = Session.get 'audioFile'
    if audio
      blob = new Blob([ audio.file ], type: audio.type)
      return window.URL.createObjectURL blob
    else
      null

# template event handlers
Template.recordWeb.events =
  'click #start-recording': (e) ->
    console.log 'click #start-recording'
    e.preventDefault()
    # if !Meteor.user()
    #   # must be the logged in user
    #   console.log 'NO USER LOGGED IN'
    #   return
    mediaType = $(e.target).data('media')
    $("#stop-recording").attr("disabled", false)
    $("#start-recording").attr("disabled", true)
    $("#cancel-recording").hide()
    if mediaType is 'audio'
      $('.gps_ring').addClass('pulse')
      $('#audioCirle').hide()
    startRecording(mediaType)
    return

  'click #stop-recording': (e) ->
    console.log 'click #stop-recording'
    e.preventDefault()
    mediaType = $(e.target).data('media')
    $("#stop-recording").attr("disabled", true)
    $("#start-recording").attr("disabled", false)
    $("#cancel-recording").show()
    if mediaType is 'audio'
      $('.gps_ring').removeClass('pulse')
      $('#audioCirle').fadeIn()
    stopRecording(mediaType)
    return

  'click #cancel-recording': (e) ->
    $('.recordWeb').hide()

  'click #play-recording': (e) ->
    console.log("click #play-recording");
    $("#review_video").get(0).play()
    $("#review_audio").get(0).play()

  'click #stop-playing': (e) ->
    console.log("click #play-recording");
    $("#review_video").get(0).pause()
    $("#review_audio").get(0).pause()

  'click .delete-record': (e) ->
    if confirm('Are you sure you want to delete this?')
      Session.set 'audioFile', null
      Session.set 'videoFile', null

BinaryFileReader = read: (file, callback) ->
  reader = new FileReader
  fileInfo =
    name: file.name
    type: file.type
    size: file.size
    file: null

  reader.onload = ->
    fileInfo.file = new Uint8Array(reader.result)
    callback null, fileInfo
    return

  reader.onerror = ->
    callback reader.error
    return

  reader.readAsArrayBuffer file
  return

# ---
# generated by js2coffee 2.1.0
