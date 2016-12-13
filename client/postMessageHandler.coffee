Feeds = require '/imports/data/feeds.coffee'
formatList = (list)->
  if list.length > 1
    list.slice(0, -1).join(", ") + ", and " + list.slice(-1)[0]
  else
    list.join("")
postMessageHandler = (event)->
  if not event.origin.match(/^https:\/\/([\w\-]+\.)*bsvecosystem\.net/) then return
  try
    request = JSON.parse(event.data)
  catch
    return
  if request.type == "eha.dossierRequest"
    title = "SPA"
    url = window.location.toString()
    if url.match(/trend/)
      console.log "screenCapture starting..."
      canvas = document.querySelector('canvas')
      tempCanvas = document.createElement("canvas")
      tempCanvas.height = window.innerHeight
      tempCanvas.width = window.innerWidth
      tempCanvas.getContext("2d").drawImage(
        canvas,
        0, 0,
        canvas.width, canvas.height,
        0, 0,
        window.innerWidth, window.innerHeight
      )
      console.log "screenCapture done"
      window.parent.postMessage(JSON.stringify({
        type: "eha.dossierTag"
        screenCapture: tempCanvas.toDataURL()
        url: url
        title: "ProMED-mail Trending Countries"
      }), event.origin)
      tempCanvas.remove()
      return
    url = window.location.toString()
    start = Session.get('startDate').toISOString().split("T")[0]
    end = Session.get('endDate').toISOString().split("T")[0]
    activeTable = $('.dataTableContent').find('.active').find('.table.dataTable')
    if activeTable.length
      dataUrl = 'data:text/csv;charset=utf-8;base64,' + activeTable.tableExport(
        type: 'csv'
        outputMode: 'base64'
      )
      selectedFeeds = []
      Feeds.find().map((feed)->
        if feed.checked
          selectedFeeds.push(feed.label)
      )
      if window.location.pathname == "/"
        title = "Country mentions per capita #{start} to #{end} " +
          "on the ProMED-mail #{formatList(selectedFeeds)} feed(s)"
      else if url.match(/gbd/)
        title = "Country mentions per death from communicable disease " +
          "#{start} to #{end} on the ProMED-mail #{formatList(selectedFeeds)} feed(s)"
      window.parent.postMessage(JSON.stringify({
        type: "eha.dossierTag"
        html: """<a href='#{dataUrl}'>Download Data CSV</a><br /><a target="_blank" href='#{url}'>Open SPA</a>"""
        title: title
      }), event.origin)
window.addEventListener("message", postMessageHandler, false)
