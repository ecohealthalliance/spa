# The router is needed to make the google analytics plug-in work.
BlazeLayout.setRoot('body')

FlowRouter.route '/',
  name: 'splashPage'
  action: ->
    BlazeLayout.render 'layout',
      main: 'blindspotMap'

FlowRouter.route '/gbd',
  name: 'globalBurdenOfDisease'
  action: ->
    BlazeLayout.render 'layout',
      main: 'blindspotMap'

FlowRouter.route '/trending',
  name: 'trending'
  action: ->
    BlazeLayout.render 'layout',
      main: 'trendMap'

FlowRouter.route '/reportingDelay',
  name: 'reportingDelay'
  action: ->
    BlazeLayout.render 'layout',
      main: 'reportingDelay'
