Template.blindspotMap.onCreated ->
  Meteor.subscribe("blindspots")
  @geoJsonFeatures = new ReactiveVar([])
  $.getJSON("world.geo.json")
    .then (geoJsonData)=>
      @geoJsonFeatures.set(geoJsonData.features)
    .fail (e)->
      console.log e
Template.blindspotMap.onRendered ->
  L.Icon.Default.imagePath = 'packages/bevanhunt_leaflet/images'
  @lMap = L.map("blindspot-map").setView([49.25044, -123.137], 5)
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
  getColor = (val)->
    # return a color from the ramp based on a 0 to 1 value.
    # If the value exceeds one the last stop is used.
    ramp = chroma.scale(["#3182bd", "#deebf7"]).colors(10)
    ramp[Math.floor(10 * Math.max(0, Math.min(val, 0.99)))]
  style = (feature)->
    fillColor: getColor(
      Math.log(
        1 + 20000 * feature.properties.mentions / feature.properties.population
      )
    )
    weight: 2
    opacity: 1
    color: 'white'
    dashArray: '3'
    fillOpacity: 0.7
  zoomToFeature = (e)=>
    @lMap.fitBounds(e.target.getBounds())
  highlightFeature = (e)=>
    layer = e.target
    layer.setStyle
      weight: 5
      color: '#666'
      dashArray: ''
      fillOpacity: 0.7
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
      <b>#{props.NAME}</b><br />
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
    console.log Blindspots.find().count()
    blindspots.map (countryInYear)->
      if countryInYear.ISO not of totalMentionsByCountry
        totalMentionsByCountry[countryInYear.ISO] = 0
      totalMentionsByCountry[countryInYear.ISO] += countryInYear.mentions
      populationByCountry[countryInYear.ISO] = countryInYear.Population
    processedFeatures = geoJsonFeatures.map (country)->
      result = EJSON.clone(country)
      # TODO: France and Norway ISO_A2 codes don't seem to match the codes from geonames.org
      result.properties.mentions = totalMentionsByCountry[country.properties.ISO_A2]
      result.properties.population = populationByCountry[country.properties.ISO_A2]
      result
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
    updateMap(@geoJsonFeatures.get(), Blindspots.find().fetch())
Template.blindspotMap.events
  'click #sidebar-plus-button': (event, instance) ->
    instance.lMap.zoomIn()
  'click #sidebar-minus-button': (event, instance) ->
    instance.lMap.zoomOut()
