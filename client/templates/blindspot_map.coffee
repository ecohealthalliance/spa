Template.blindspotMap.onCreated ->
  Meteor.subscribe("blindspots")
  @startYear = new ReactiveVar(1999)
  @endYear = new ReactiveVar(2000)
  @geoJsonFeatures = new ReactiveVar([])
  $.getJSON("world.geo.json")
    .then (geoJsonData)=>
      @geoJsonFeatures.set(geoJsonData.features)
    .fail (e)->
      console.log e
  @minYear = new ReactiveVar(1994)
  @maxYear = new ReactiveVar(2015)
  Blindspots.find().observeChanges(
    added: (id, fields)=>
      if fields.year < @minYear.get()
        @minYear.set(fields.year)
      else if fields.year > @maxYear.get()
        @maxYear.set(fields.year)
  )
Template.blindspotMap.onRendered ->
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

  sidebar = L.control.sidebar('sidebar').addTo(@lMap)
  tableSidebar = L.control.sidebar('tableSidebar').addTo(@lMap)

  getColor = (val)->
    # return a color from the ramp based on a 0 to 1 value.
    # If the value exceeds one the last stop is used.
    ramp = chroma.scale(["#9e5324", "#F8ECE0"]).colors(10)
    ramp[Math.floor(10 * Math.max(0, Math.min(val, 0.99)))]
  style = (feature)=>
    fillColor: getColor(
      Math.log(
        1 + 1000000 * feature.properties.mentions / (
          (@endYear.get() - @startYear.get()) * feature.properties.population
        )
      )
    )
    weight: 1
    opacity: 1
    color: '#CDD2D4'
    dashArray: '3'
  zoomToFeature = (e)=>
    @lMap.fitBounds(e.target.getBounds())
  highlightFeature = (e)=>
    layer = e.target
    layer.setStyle
      weight: 1
      color: '#2CBA74'
      dashArray: ''
      fillOpacity: 0.8
    if not L.Browser.ie and not L.Browser.opera
      layer.bringToFront()
    info.update(layer.feature.properties)
  resetHighlight = (e)=>
    @geoJsonLayer.resetStyle(e.target)
    info.update()
  info = L.control()
  info.onAdd = (map) ->
    @_div = L.DomUtil.create('div', 'info')
    @update()
    @_div
  info.update = (props) ->
    if props
      @_div.innerHTML = """
      <b>#{props.name}</b><br />
      Population: #{props.population}<br />
      Mentions: #{props.mentions}
      """
    else
      @_div.innerHTML = 'Hover over a country'
  info.addTo(@lMap)
  @geoJsonLayer = null

  updateMap = _.throttle((geoJsonFeatures, blindspots)=>
    totalMentionsByCountry = {}
    populationByCountry = {}
    blindspots.map (countryInYear)->
      if countryInYear.ISO not of totalMentionsByCountry
        totalMentionsByCountry[countryInYear.ISO] = 0
      totalMentionsByCountry[countryInYear.ISO] += countryInYear.mentions
      populationByCountry[countryInYear.ISO] = countryInYear.Population

    #BMA: Something like this
    # Template.spaTable.blindSpotsTable.set blindspots.map

    processedFeatures = geoJsonFeatures.map (country)->
      country.properties.mentions = totalMentionsByCountry[country.properties.ISO2]
      country.properties.population = populationByCountry[country.properties.ISO2]
      country
    if @geoJsonLayer
      @lMap.removeLayer(@geoJsonLayer)
    @geoJsonLayer = L.geoJson({
        features: processedFeatures
        type: "FeatureCollection"
      }, {
      style: style
      onEachFeature: (feature, layer)->
        layer.on
          mouseover: highlightFeature
          mouseout: resetHighlight
          click: zoomToFeature
    }).addTo(@lMap)
  , 10000)

  @autorun =>
    updateMap(@geoJsonFeatures.get(), Blindspots.find(
      $and: [
        {
          year:
            $gte: @startYear.get()
        }
        {
          year:
            $lte: @endYear.get()
        }
      ]
    ).fetch())

Template.blindspotMap.helpers
  minYear: ->
    Template.instance().minYear
  maxYear: ->
    Template.instance().maxYear
  startYear: ->
    Template.instance().startYear.get()
  endYear: ->
    Template.instance().endYear.get()
Template.blindspotMap.events
  'click #sidebar-plus-button': (event, instance) ->
    instance.lMap.zoomIn()
  'click #sidebar-minus-button': (event, instance) ->
    instance.lMap.zoomOut()
  "update #slider": _.debounce((evt, instance)->
    yearRange = $(evt.target)[0].noUiSlider.get()
    instance.startYear.set(parseInt(yearRange[0]))
    instance.endYear.set(parseInt(yearRange[1]))
  , 200)
