Template.pageSelector.helpers
  pages: ->
    FlowRouter.watchPathChange()
    [
      {
        label: "Mentions"
        subLabel: "per capita"
        path: "/"
      }
      {
        label: "Mentions"
        subLabel: "per death"
        path: "/gbd"
      }
      {
        label: "Trending countries"
        path: "/trending"
      }
    ].map (page)->
      if page.path == FlowRouter.current().path
        page.active = true
      return page
