Router.configure
  layoutTemplate: 'layout'
  loadingTemplate: 'loading'
  notFoundTemplate: 'not_found'


Router.map ->
  # Home
  @route "/",
    name: 'homePage'
    waitOn: ->
      Meteor.subscribe "locations"

  @route "/upload",
    name: 'uploadMedia'
