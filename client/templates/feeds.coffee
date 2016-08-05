Feeds = require '/imports/data/feeds.coffee'

Template.feeds.helpers
  feeds: ->
    Feeds.find()

Template.feeds.events
  'click .feed input': (event, instance) ->
    Feeds.update(@_id, $set: {checked:event.target.checked})
