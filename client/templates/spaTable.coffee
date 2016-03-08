Template.spaTable.onCreated ->
  @sortBy = new ReactiveVar('Country')
  @sortOrder = new ReactiveVar(1)

Template.spaTable.helpers
  cells: ->
    [
      { name: 'Country', title: "Country" },
      { name: 'mentions', title: "Mentions" },
      { name: 'Population', title: "Population" }
    ]
  data: ->
    instance = Template.instance()
    sortBy = instance.sortBy.get()
    sortOrder = instance.sortOrder.get()
    _countries = {}
    _sort = {}
    _sort[sortBy] = sortOrder
    Blindspots.find({}, {sort: _sort}).forEach (item, i) ->
      unless _countries[item.ISO]
        _countries[item.ISO] = {name: item.Country, mentions: 0, population: 0}
      _countries[item.ISO].mentions += item.mentions
      _countries[item.ISO].population += item.Population
      true
    countries = []
    for key, country of _countries
      countries.push country
    countries

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
