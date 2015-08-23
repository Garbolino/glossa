Router.configure
  layoutTemplate: 'layout'
  loadingTemplate: 'loading'
  notFoundTemplate: 'not_found'

AccountsTemplates.configureRoute 'signIn',
  name: 'signIn'
  path: '/login'
  layoutTemplate: 'layout'
  redirect: '/'

Router.map ->
  # Home
  @route "/",
    name: 'homePage'
    waitOn: ->
      Meteor.subscribe "locations"

  @route "/upload",
    name: 'uploadMedia'

  @route "/:slug",
    name: 'locationPage'
    waitOn: ->
      Meteor.subscribe "location", @params.slug
    data: ->
      location: Locations.findOne {slug: @params.slug}

  @route "/:slug/:_id",
    name: 'mediaPage'


Router.plugin 'ensureSignedIn', only: [
  'uploadMedia'
]
