Template.spaTable.onCreated ->
  @ready = new ReactiveVar false
  @sortBy = new ReactiveVar 'mentions'
  @sortOrder = new ReactiveVar 0
  @countries = new Meteor.Collection(null)
  @autorun =>
    @ready.set(false)
    @countries.remove({})
    _countries = {}
    Blindspots.find().forEach (item, i) ->
      unless _countries[item.ISO]
        _countries[item.ISO] = {name: item.Country, mentions: 0, population: 0}
      _countries[item.ISO].mentions += item.mentions
      _countries[item.ISO].population += item.Population
      true
    for ISO, country of _countries
      @countries.insert(country)
    @ready.set(true)

Template.spaTable.helpers
  cells: ->
    [
      { name: 'name', title: "Country" },
      { name: 'mentions', title: "Mentions" },
      { name: 'population', title: "Population" }
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
