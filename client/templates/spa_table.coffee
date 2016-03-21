Template.spaTable.onCreated ->
  @ready = new ReactiveVar false
  @sortBy = new ReactiveVar 'mentionsPerCapita'
  @sortOrder = new ReactiveVar 1
  @countries = new Meteor.Collection(null)
  @aggregatedCountryData = @data.aggregatedCountryData
  @autorun =>
    @ready.set(false)
    @countries.remove({})
    for ISO, country of @aggregatedCountryData.get()
      @countries.insert(country)
    @ready.set(true)
Template.spaTable.helpers
  startDate: ->
    Session.get('startDate').toLocaleDateString()
  endDate: ->
    Session.get('endDate').toLocaleDateString()
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
    # The mongo sort doesn't group NaNs so a custom sort function is used.
    _.sortBy(instance.countries.find({}).fetch(), (item)->
      value = item[instance.sortBy.get()]
      if _.isNaN(value)
        return -1 * instance.sortOrder.get()
      else
       return value * instance.sortOrder.get()
    )

  ready: ->
    Template.instance().ready.get()

  sortDirectionClass: ->
    instance = Template.instance()
    if @name == instance.sortBy.get()
      if instance.sortOrder.get() == 1
        'tablesorter-headerAsc'
      else
        'tablesorter-headerDesc'

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
