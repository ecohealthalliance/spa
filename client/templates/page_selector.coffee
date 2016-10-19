Template.pageSelector.helpers
  pages: ->
    FlowRouter.watchPathChange()
    [
      {
        label: "Mentions per capita"
        path: "/"
      }
      {
        label: "Mentions per death from communicable disease"
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
