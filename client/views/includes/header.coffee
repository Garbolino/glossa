Template.header.events
   'click #logout': (e) ->
      e.preventDefault()
      AccountsTemplates.logout()
