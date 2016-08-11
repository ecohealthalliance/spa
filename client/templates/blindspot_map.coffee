Feeds = require '/imports/data/feeds.coffee'

COLOR_CONSTANT = 20000000000000000
round = (num, positions)->
  magnitude = Math.pow(10, positions)
  Math.round(magnitude * num) / magnitude

formatDate = (d)->
  day = ('0' + d.getDate()).slice(-2)
  month = ('0' + (d.getMonth() + 1)).slice(-2)
  year = String(d.getFullYear()).slice(-2)
  "#{month}/#{day}/#{year}"

# These take a javascript datetimes and truncate the time component so that it
# is either the start or end of the day respectively.
truncateDateToStart = (d)->
  d.setHours(0)
  d.setMinutes(0)
  d.setSeconds(0)
  d
truncateDateToEnd = (d)->
  d.setHours(23)
  d.setMinutes(59)
  d.setSeconds(59)
  d

Template.blindspotMap.onCreated ->
  @aggregatedCountryDataRV = new ReactiveVar {}
  @sideBarLeftOpen = new ReactiveVar true
  @sideBarRightOpen = new ReactiveVar false
  Session.set('startDate', new Date('1/1/1999'))
  Session.set('endDate', new Date('1/1/2000'))
  @geoJsonFeatures = new ReactiveVar []
  @mapLoading = new ReactiveVar true
  @geoJsonFeaturesPromise = $.getJSON("/world.geo.json")
    .fail (e)->
      console.log e
  @minDate = new ReactiveVar truncateDateToStart(new Date('1/1/1994'))
  @maxDate = new ReactiveVar truncateDateToEnd(new Date('1/1/2016'))
  @intervalStartDate = new ReactiveVar new Date('1/1/1994')
  @intervalEndDate = new ReactiveVar new Date('1/1/2016')
  Meteor.call 'getPostsDateRange', (err, [startDate, endDate])=>
    console.log("Most recent article date:", endDate)
    @minDate.set startDate
    @maxDate.set endDate
    @intervalStartDate.set startDate
    @intervalEndDate.set endDate

Template.blindspotMap.onRendered ->
  @$('[data-toggle="tooltip"]').tooltip()
  @autorun =>
    @$('#intervalStartDate').data('DateTimePicker')?.destroy()
    @$('#intervalStartDate').datetimepicker(
      format: 'MM/DD/YY'
      minDate: truncateDateToStart @minDate.get()
      maxDate: truncateDateToEnd @maxDate.get()
    )
    @$('#intervalEndDate').data('DateTimePicker')?.destroy()
    @$('#intervalEndDate').datetimepicker(
      format: 'MM/DD/YY'
      minDate: truncateDateToStart @minDate.get()
      maxDate: truncateDateToEnd @maxDate.get()
    )
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
  @lMap = L.map("blindspot-map", zoomControl: false).setView([49.25044, -123.137], 4)
  layer = L.tileLayer('//cartodb-basemaps-{s}.global.ssl.fastly.net/light_all/{z}/{x}/{y}.png', {
    attribution: """Map tiles by <a href="http://cartodb.com/attributions#basemaps">CartoDB</a>,
    under <a href="https://creativecommons.org/licenses/by/3.0/">CC BY 3.0</a>.
    Data by <a href="http://www.openstreetmap.org/">OpenStreetMap</a>, under ODbL.
    <br>
    CRS:
    <a href="http://wiki.openstreetmap.org/wiki/EPSG:3857" >
    EPSG:3857
    </a>,
    Projection: Spherical Mercator""",
    subdomains: 'abcd',
    type: 'osm'
    noWrap: true
    minZoom: 1
    maxZoom: 18
  }).addTo(@lMap)

  ramp = chroma.scale(["#9e5324", "#F8ECE0"]).colors(10)

  legend = L.control(position: 'bottomright')
  legend.onAdd = (map)->
    @_div = L.DomUtil.create('div', 'info legend')
    @update()
  legend.update = ()->
    $(@_div).html(
      Blaze.toHTMLWithData(Template.legend, {
        values: _.range(0, ramp.length, 2).map (idx)->
          value: round((Math.exp(idx / ramp.length) - 1) * 1000000 * (
            1000 * 60 * 60 * 24 * 365 # 1 year in milliseconds
          ) / COLOR_CONSTANT, 2)
          color: ramp[idx]
      })
    )
    @_div
  legend.addTo(@lMap)

  sidebar = L.control.sidebar('sidebar').addTo(@lMap)
  tableSidebar = L.control.sidebar('tableSidebar').addTo(@lMap)
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
      fillColor: getColor(
        Math.log(
          1 + COLOR_CONSTANT * (aggregatedCountryData[feature.properties.ISO2]?.mentionsPerCapita) / (
            (Session.get('endDate') - Session.get('startDate'))
          )
        )
      )
      weight: 1
      opacity: 1
      color: '#DDDDDD'
      dashArray: '3'
      fillOpacity: 0.75
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
        <h2>#{addCommas(countryData.name)}</h2>
        <ul class='list-unstyled'>
          <li><span>Mentions:</span> #{addCommas(countryData.mentions)}</li>
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
      Meteor.call('aggregateMentionsOverDateRange', {
        startDate: Session.get('startDate')
        endDate: Session.get('endDate')
        feedIds: _.flatten(
          Feeds.find().map((feed)-> if feed.checked then [feed._id] else [])
        )
      }, (err, mentionsByCountry)=>
          if err
            throw err
          groupedCountryData = _.chain(geoJsonFeatures)
            .map((feature)->
              {properties: {ISO2, population, name}} = feature
              mentions = mentionsByCountry[ISO2] or 0
              {
                name: name
                ISO2: ISO2
                population: population
                mentions: mentions
                mentionsPerCapita: mentions / population
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
          @aggregatedCountryDataRV.set aggregatedCountryData
          updateMap()
      )

Template.blindspotMap.helpers
  minDate: ->
    Template.instance().minDate.get().toLocaleDateString()
  maxDate: ->
    Template.instance().maxDate.get().toLocaleDateString()
  intervalStartDate: ->
    Template.instance().intervalStartDate
  intervalEndDate: ->
    Template.instance().intervalEndDate
  formattedIntervalStartDate: ->
    formatDate Template.instance().intervalStartDate.get()
  formattedIntervalEndDate: ->
    formatDate Template.instance().intervalEndDate.get()
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
    Session.set('startDate', truncateDateToStart(new Date(parseFloat(range[0]))))
    Session.set('endDate', truncateDateToEnd(new Date(parseFloat(range[1]))))
  , 200)
  'dp.change #intervalStartDate': (event, instance)->
    d = $(event.target).data('DateTimePicker')?.date().toDate()
    if d then instance.intervalStartDate.set d
  'dp.change #intervalEndDate': (event, instance)->
    d = $(event.target).data('DateTimePicker')?.date().toDate()
    if d then instance.intervalEndDate.set d
  'click #sidebar-collapse-tab': (event, instance) ->
    sideBarLeftOpen = instance.sideBarLeftOpen.get()
    $('body').toggleClass('sidebar-left-closed')
    instance.sideBarOpen.set not sideBarOpen
  'click #sidebar-table-tab': (event, instance) ->
    sideBarRightOpen = instance.sideBarRightOpen.get()
    $('body').toggleClass('sidebar-right-closed')
    instance.sideBarRightOpen.set not sideBarRightOpen
