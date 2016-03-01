Meteor.publish 'blindspots', =>
  @Blindspots.find()
