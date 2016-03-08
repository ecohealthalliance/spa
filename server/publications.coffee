Meteor.publish 'blindspots', =>
  @Blindspots.find({}, {
    fields:
      ISO: 1
      Country: 1
      year: 1
      mentions: 1
      Population: 1
  })
