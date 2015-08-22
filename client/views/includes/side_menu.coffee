Template.sideMenu.helpers(
  'isRouteActive': () ->
    args = Array::slice.call(arguments, 0)
    args.pop()
    active = _.any(args, (name) ->
      Router.current() and (Router.current().route.getName().toLowerCase()).indexOf(name) isnt -1
    )
    active and 'active'

  'activeSubMenu': () ->
    args = Array::slice.call(arguments, 0)
    args.pop()
    active = _.any(args, (name) ->
      Router.current() and Router.current().route.getName() is name
    )
    active and 'active'
)
