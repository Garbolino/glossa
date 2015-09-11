Slingshot.createDirective 'myFileUploads', Slingshot.S3Storage,
  bucket: 'glossa-ph'
  acl: 'public-read'
  AWSAccessKeyId: Meteor.settings.aws.client_id
  AWSSecretAccessKey: Meteor.settings.aws.client_secret
  maxSize: 10 * 1024 * 1024 #10 MB (use null for unlimited)
  allowedFileTypes: ["image/png", "image/jpeg", "video/webm", "audio/wav", "audio/3gpp"]
  authorize: ->
    # Deny uploads if user is not logged in
    if !@userId
      message = 'Please login before posting files'
      throw new (Meteor.Error)('Login Required', message)
    true
  key: (file, metaContext) ->
    #Store file into a directory by the user's username.
    user = Meteor.users.findOne @userId
    "#{user.username}/#{metaContext.mediaType}/#{metaContext.recorderBy}/#{file.name}"
