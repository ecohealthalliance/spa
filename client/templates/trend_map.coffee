Feeds = require '/imports/data/feeds.coffee'
WorldGeoJSON = require '/imports/data/world.geo.json'
utils = require '/imports/utils.coffee'

Template.trendMap.onCreated ->
  @valRange = new ReactiveVar []
  @trendingRange = new ReactiveVar 'week'
  @aggregatedCountryDataRV = new ReactiveVar {}
  @sideBarLeftOpen = new ReactiveVar true
  @mapLoading = new ReactiveVar true

Template.trendMap.onRendered ->
  @$('[data-toggle="tooltip"]').tooltip()
  instance = @
  L.Icon.Default.imagePath = 'packages/bevanhunt_leaflet/images'
  @lMap = L.map("blindspot-map",
    zoomControl: false
    preferCanvas: true
  ).setView([49.25044, -123.137], 4)

  ramp = chroma.scale(["#ff0000", '#dddddd', '#dddddd', "#00ff00"]).colors(10)

  sidebar = L.control.sidebar('sidebar').addTo(@lMap)
  geoJsonFeatures = WorldGeoJSON.features
  aggregatedCountryData = {}
  getColor = (val)->
    # return a color from the ramp based on a 0 to 1 value.
    # If the value exceeds one the last stop is used.
    ramp[Math.floor(ramp.length * Math.max(0, Math.min(val, 0.99)))]

  style = (feature)=>
    normalizedScore = 0.5
    score = aggregatedCountryData[feature.properties.ISO2]?.scorePerCapita
    [minVal, maxVal] = @valRange.get()
    if score < 0
      normalizedScore -= 0.5 * score / minVal
    else
      normalizedScore += 0.5 * score / maxVal
    return {
      fillColor: getColor(normalizedScore)
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
    unless _.isEmpty(aggregatedCountryData)
      instance.mapLoading.set false
      $(window).off 'resize'
    countryLayers.forEach (layer)=>
      @geoJsonLayer.resetStyle(layer)

  @autorun =>
    instance.mapLoading.set true
    Meteor.call('trendingCountries', {
      startDate: moment().subtract(4, instance.trendingRange.get()).toDate()
      recentCutoffDate: moment().subtract(1, instance.trendingRange.get()).toDate()
      feedIds: _.flatten(
        Feeds.find().map((feed)-> if feed.checked then [feed._id] else [])
      )
    }, (err, mentionsByCountry)=>
      if err
        throw err
      groupedCountryData = _.chain(geoJsonFeatures)
        .map((feature)->
          {properties: {ISO2, population, name}} = feature
          score = mentionsByCountry[ISO2] or 0
          {
            name: name
            ISO2: ISO2
            population: population
            score: score
            scorePerCapita: score / population
          }
        )
        .groupBy("ISO2")
        .value()
      aggregatedCountryData = {}
      for ISO2, features of groupedCountryData
        aggregatedCountryData[ISO2] = features[0]
      majorCountryData = _.values(aggregatedCountryData).filter((d)->
        d.population > 1000000
      )
      @valRange.set [
        _.chain(majorCountryData).pluck('scorePerCapita').min().value()
        _.chain(majorCountryData).pluck('scorePerCapita').max().value()
      ]
      updateMap()
    )

Template.trendMap.helpers
  loading: ->
    Template.instance().mapLoading.get()

  rangeSelected: (range) ->
    range is Template.instance().trendingRange.get()


Template.trendMap.events
  'click #sidebar-plus-button': (event, instance) ->
    instance.lMap.zoomIn()
  'click #sidebar-minus-button': (event, instance) ->
    instance.lMap.zoomOut()
  'click #sidebar-collapse-tab': (event, instance) ->
    sideBarLeftOpen = instance.sideBarLeftOpen.get()
    $('body').toggleClass('sidebar-left-closed')
    instance.sideBarOpen.set not sideBarOpen
  'click #trendingRange li': (event, template) ->
    template.trendingRange.set($(event.target).data('time'))
