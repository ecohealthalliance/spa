Feeds = require '/imports/data/feeds.coffee'

Template.trendMap.onCreated ->
  @valRange = new ReactiveVar []
  @trendingRange = new ReactiveVar 'week'
  @aggregatedCountryDataRV = new ReactiveVar {}
  @sideBarLeftOpen = new ReactiveVar true
  @geoJsonFeatures = new ReactiveVar []
  @mapLoading = new ReactiveVar true
  @geoJsonFeaturesPromise = $.getJSON("/world.geo.json")
    .fail (e)->
      console.log e

Template.trendMap.onRendered ->
  @$('[data-toggle="tooltip"]').tooltip()
  centerLoadingSpinner = ->
    loadingContainerWidth = $('.loading-content').width() or 100
    leftSideBarWidth = $('#sidebar').width()
    rightSideBarWidth = $('.sidebarRight .sidebar-content').width()
    mapViewWidth = $(document).width() - leftSideBarWidth
    loadingSpinnerPosition = mapViewWidth / 2 - loadingContainerWidth / 2 + rightSideBarWidth / 2
    $('.loading-content').css 'right', "#{loadingSpinnerPosition}px"
  centerLoadingSpinner()
  $(window).resize ->
    centerLoadingSpinner()

  instance = @
  L.Icon.Default.imagePath = 'packages/bevanhunt_leaflet/images'
  @lMap = L.map("blindspot-map",
    zoomControl: false
    preferCanvas: true
  ).setView([49.25044, -123.137], 4)

  ramp = chroma.scale(["#ff0000", '#dddddd', '#dddddd', "#00ff00"]).colors(10)

  sidebar = L.control.sidebar('sidebar').addTo(@lMap)
  @geoJsonFeaturesPromise.then ({features: geoJsonFeatures})=>
    # For countries without an ISO2 code use their name instead
    for feature in geoJsonFeatures
      if feature.properties.ISO2 == "-99"
        feature.properties.ISO2 = "NoISO2:" + feature.properties.name
    aggregatedCountryData = {}
    getColor = (val)->
      # return a color from the ramp based on a 0 to 1 value.
      # If the value exceeds one the last stop is used.
      ramp[Math.floor(ramp.length * Math.max(0, Math.min(val, 0.99)))]
    addCommas = (num)=>
      num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
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
      if props
        L.DomUtil.addClass(@_div, 'active')
        countryData = aggregatedCountryData[props.ISO2]
        @_div.innerHTML = """
        <h2>#{countryData.name}</h2>
        <ul class='list-unstyled'>
          <li><span>Population:</span> #{addCommas(countryData.population)}</li>
        </ul>
        """
      else
        L.DomUtil.removeClass(@_div, 'active')
        @_div.innerHTML = """
        <p>Hover over a country to view its number of mentions and population.</p>
        """
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
      centerLoadingSpinner()
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
          if features.length > 1
            console.log ISO2 + " has multiple features associated with it."
            console.log features
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

Template.trendMap.events
  'click #sidebar-plus-button': (event, instance) ->
    instance.lMap.zoomIn()
  'click #sidebar-minus-button': (event, instance) ->
    instance.lMap.zoomOut()
  'click #sidebar-collapse-tab': (event, instance) ->
    sideBarLeftOpen = instance.sideBarLeftOpen.get()
    $('body').toggleClass('sidebar-left-closed')
    instance.sideBarOpen.set not sideBarOpen
  'change #trendingRange': (event, template) ->
    template.trendingRange.set($("#trendingRange").val())
