Template.spaTable.onCreated ->
  @ready = new ReactiveVar false
  @sortBy = new ReactiveVar 'mentionsPerCapita'
  @sortOrder = new ReactiveVar 0
  @countries = new Meteor.Collection(null)
  @autorun =>
    @ready.set(false)
    @countries.remove({})
    _countries = {}
    yearMin = Session.get('startYear')
    yearMax = Session.get('endYear')
    Blindspots.find({year: {$gte: yearMin, $lt: yearMax}}).forEach (item, i) ->
      unless _countries[item.ISO]
        _countries[item.ISO] = {name: item.Country, mentions: 0, population: 0}
      _countries[item.ISO].mentions += item.mentions
      _countries[item.ISO].population += item.Population
      true
    for ISO, country of _countries
      country.mentionsPerCapita = country.mentions / country.population || 0
      @countries.insert(country)
    @ready.set(true)

Template.spaTable.helpers
  startYear: ->
    Session.get('startYear')
  endYear: ->
    Session.get('endYear')
  cells: ->
    [
      { name: 'name', title: "Country" },
      { name: 'mentions', title: "Mentions" },
      { name: 'population', title: "Population" }
      { name: 'mentionsPerCapita', title: "Mentions per capita" },
    ]
  data: ->
    instance = Template.instance()
    _sort = {}
    _sort[instance.sortBy.get()] = instance.sortOrder.get()
    instance.countries.find({}, {sort: _sort})
  ready: ->
    Template.instance().ready.get()

Template.spaTable.events
  'click th': (event, instance) ->
    target = event.currentTarget
    currentSortBy = instance.sortBy.get()
    newSortBy = target.getAttribute('aria-sort')
    if newSortBy != currentSortBy
      instance.sortBy.set(newSortBy)
      instance.sortOrder.set(1) # reset back to 1
    else
      instance.sortOrder.set(-instance.sortOrder.get())
  'click .exportData': (event, instance) ->
    instance.$('.dtHidden').show()
    fileType = $(event.currentTarget).attr("data-type")
    activeTable = instance.$('.dataTableContent').find('.active').find('.table.dataTable')
    if activeTable.length
      activeTable.tableExport({type: fileType})
    instance.$('.dtHidden').hide()
    return
