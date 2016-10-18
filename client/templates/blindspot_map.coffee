Feeds = require '/imports/data/feeds.coffee'
WorldGeoJSON = require '/imports/data/world.geo.json'
utils = require '/imports/utils.coffee'

Template.blindspotMap.onCreated ->
  @aggregatedCountryDataRV = new ReactiveVar {}
  @sideBarLeftOpen = new ReactiveVar true
  @sideBarRightOpen = new ReactiveVar false
  @mapLoading = new ReactiveVar true
  @minDate = new ReactiveVar null
  @maxDate = new ReactiveVar null
  # The interval dates set the start and end of the time slider's min/max range.
  @intervalStartDate = new ReactiveVar new Date()
  @intervalEndDate = new ReactiveVar new Date()
  Meteor.call 'getPostsDateRange', (err, [startDate, endDate])=>
    console.log("Most recent article date:", endDate)
    startDate = utils.truncateDateToStart(startDate)
    endDate = utils.truncateDateToEnd(endDate)
    @minDate.set startDate
    @maxDate.set endDate
    @intervalStartDate.set startDate
    @intervalEndDate.set endDate
    Session.set 'startDate', startDate
    Session.set 'endDate', endDate
  # When the interval dates change reset the start/end dates to the full interval.
  @autorun =>
    Session.set 'startDate', @intervalStartDate.get()
    Session.set 'endDate', @intervalEndDate.get()
Template.blindspotMap.onRendered ->
  @autorun =>
    [minDate, maxDate] = [@minDate.get(), @maxDate.get()]
    # Wait until the date range has been established
    if not minDate then return
    @$('[data-toggle="tooltip"]').tooltip()
    @$('#intervalStartDate').data('DateTimePicker')?.destroy()
    @$('#intervalStartDate').datetimepicker(
      format: 'MM/DD/YYYY'
      minDate: minDate
      maxDate: maxDate
    )
    @$('#intervalEndDate').data('DateTimePicker')?.destroy()
    @$('#intervalEndDate').datetimepicker(
      format: 'MM/DD/YYYY'
      minDate: minDate
      maxDate: maxDate
    )
  L.Icon.Default.imagePath = 'packages/bevanhunt_leaflet/images'
  @lMap = L.map("blindspot-map",
    zoomControl: false
    preferCanvas: true
  ).setView([49.25044, -123.137], 4)

  ramp = chroma.scale(["#441152", "#3e5088", "#29928b", "#4bbf72"]).colors(10)

  legend = L.control(position: 'bottomright')
  legend.onAdd = (map)->
    @_div = L.DomUtil.create('div', 'info legend')
    @update()
  legend.update = ()->
    $(@_div).html(
      Blaze.toHTMLWithData(Template.legend, {
        values: _.range(0, ramp.length, 2).map (idx)->
          value: utils.round(
            (idx / ramp.length) * medianValue * 1000000 / 0.5
          , 2)
          color: ramp[idx]
      })
    )
    @_div
  legend.addTo(@lMap)

  sidebar = L.control.sidebar('sidebar').addTo(@lMap)
  tableSidebar = L.control.sidebar('tableSidebar').addTo(@lMap)
  geoJsonFeatures = WorldGeoJSON.features
  aggregatedCountryData = {}
  getColor = (val)->
    # return a color from the ramp based on a 0 to 1 value.
    # If the value exceeds one the last stop is used.
    ramp[Math.floor(ramp.length * Math.max(0, Math.min(val, 0.99)))]
  style = (feature)=>
    if FlowRouter.getRouteName() == "globalBurdenOfDisease"
      x = aggregatedCountryData[feature.properties.ISO2]?.mentionsPerDeathPerYear
    else
      x = aggregatedCountryData[feature.properties.ISO2]?.mentionsPerCapitaPerYear
    return {
      fillColor: getColor(x * 0.5 / medianValue)
      weight: 1
      opacity: 1
      color: '#DDDDDD'
      dashArray: '3'
      fillOpacity: 0.75
    }
  zoomToFeature = (e)=>
    @lMap.fitBounds(e.target.getBounds())
  highlightFeature = (e)=>
    layer = e.target
    layer.setStyle
      weight: 1
      color: '#2CBA74'
      dashArray: ''
      fillOpacity: 0.75
    if not L.Browser.ie and not L.Browser.opera
      layer.bringToFront()
    info.update(layer.feature.properties)
  resetHighlight = (e)=>
    @geoJsonLayer.resetStyle(e.target)
    info.update()
  info = L.control(position: 'topleft')
  info.onAdd = (map) ->
    @_div = L.DomUtil.create('div', 'info')
    @update()
    @_div
  info.update = (props) ->
    @_div.innerHTML = Blaze.toHTMLWithData(Template.infoBox, {
      props: props
      countryData: if props?.ISO2 then aggregatedCountryData[props.ISO2]
    })
  info.addTo(@lMap)
  countryLayers = []
  @geoJsonLayer = L.geoJson({
    features: geoJsonFeatures
    type: "FeatureCollection"
  }, {
    style: style
    onEachFeature: (feature, layer)->
      countryLayers.push(layer)
      layer.on
        mouseover: highlightFeature
        mouseout: resetHighlight
        click: zoomToFeature
  }).addTo(@lMap)

  updateMap = =>
    legend.update()
    countryLayers.forEach (layer)=>
      @geoJsonLayer.resetStyle(layer)
    unless _.isEmpty(aggregatedCountryData)
      @mapLoading.set false
  summaryStats = {}
  medianValue = null
  @autorun =>
    args =
      startDate: Session.get('startDate')
      endDate: Session.get('endDate')
      feedIds: _.flatten(
        Feeds.find().map((feed)-> if feed.checked then [feed._id] else [])
      )
    # Wait until the date range has been established
    if not @minDate.get() then return
    @mapLoading.set true
    Meteor.call('aggregateMentionsOverDateRange', args, (err, mentionsByCountry)=>
      if err
        throw err
      aggregatedCountryData = {}
      aggregatedCountryData = _.chain(geoJsonFeatures)
        .map((feature)->
          {properties: {ISO2, population, name}} = feature
          mentions = mentionsByCountry[ISO2] or 0
          YEAR_IN_MILLIS = 1000 * 60 * 60 * 24 * 365
          timeIntervalYears = (
            Session.get('endDate') - Session.get('startDate')
          ) / YEAR_IN_MILLIS
          return {
            name: name
            ISO2: ISO2
            population: population
            mentions: mentions
            mentionsPerCapita: mentions / population
            mentionsPerCapitaPerYear: (mentions / population) / timeIntervalYears
            mentionsPerDeathPerYear: null #TODO
          }
        )
        .groupBy("ISO2")
        .value()

      for ISO2, features of aggregatedCountryData
        aggregatedCountryData[ISO2] = features[0]
      @aggregatedCountryDataRV.set aggregatedCountryData
    )
  @autorun =>
    # Run on route name change
    if FlowRouter.getRouteName() == "globalBurdenOfDisease"
      pluckProp = 'mentionsPerDeathPerYear'
    else
      pluckProp = 'mentionsPerCapitaPerYear'
    routeName = FlowRouter.getRouteName()
    aggregatedCountryData = @aggregatedCountryDataRV.get()
    if not _.isEmpty(aggregatedCountryData)
      values = _.chain(aggregatedCountryData)
        .values(aggregatedCountryData)
        .pluck(pluckProp)
        .value()
        .sort()
      medianValue = values[Math.floor(values.length/2)]
      updateMap()

Template.blindspotMap.helpers
  minDate: ->
    Template.instance().minDate.get()?.toLocaleDateString()
  maxDate: ->
    Template.instance().maxDate.get()?.toLocaleDateString()
  intervalStartDate: ->
    Template.instance().intervalStartDate
  intervalEndDate: ->
    Template.instance().intervalEndDate
  formattedIntervalStartDate: ->
    moment(Template.instance().intervalStartDate.get()).format("MM/DD/YYYY")
  formattedIntervalEndDate: ->
    moment(Template.instance().intervalEndDate.get()).format("MM/DD/YYYY")
  intervalGreaterThanOneDay: ->
    (Template.instance().intervalEndDate.get() - Template.instance().intervalStartDate.get()) > 1000 * 60 * 60 * 24
  startDate: ->
    Session.get('startDate').toLocaleDateString()
  endDate: ->
    Session.get('endDate').toLocaleDateString()
  loading: ->
    Template.instance().mapLoading.get()
  aggregatedCountryData: ->
    Template.instance().aggregatedCountryDataRV

Template.blindspotMap.events
  'click #sidebar-plus-button': (event, instance) ->
    instance.lMap.zoomIn()
  'click #sidebar-minus-button': (event, instance) ->
    instance.lMap.zoomOut()
  'update #slider': _.debounce((evt, instance)->
    range = $(evt.target)[0].noUiSlider.get()
    Session.set('startDate', utils.truncateDateToStart(new Date(parseFloat(range[0]))))
    Session.set('endDate', utils.truncateDateToEnd(new Date(parseFloat(range[1]))))
  , 200)
  'dp.change #intervalStartDate': (event, instance)->
    d = $(event.target).data('DateTimePicker')?.date().toDate()
    if d then instance.intervalStartDate.set utils.truncateDateToStart(d)
  'dp.change #intervalEndDate': (event, instance)->
    d = $(event.target).data('DateTimePicker')?.date().toDate()
    if d then instance.intervalEndDate.set utils.truncateDateToEnd(d)
  'click #sidebar-collapse-tab': (event, instance) ->
    sideBarLeftOpen = instance.sideBarLeftOpen.get()
    $('body').toggleClass('sidebar-left-closed')
    instance.sideBarOpen.set not sideBarOpen
  'click #sidebar-table-tab': (event, instance) ->
    sideBarRightOpen = instance.sideBarRightOpen.get()
    $('body').toggleClass('sidebar-right-closed')
    instance.sideBarRightOpen.set not sideBarRightOpen
