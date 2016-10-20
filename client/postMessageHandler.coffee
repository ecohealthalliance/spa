postMessageHandler = (event)->
  if not event.origin.match(/^https:\/\/([\w\-]+\.)*bsvecosystem\.net/) then return
  try
    request = JSON.parse(event.data)
  catch
    return
  if request.type == "screenCapture"
    title = "SPA"
    url = window.location.toString()
    if window.location.pathname == "/"
      title = "ProMED-mail mentions per capita"
    else if url.match(/trend/)
      title = "ProMED-mail Trending Countries"
    else if url.match(/gbd/)
      title = "ProMED-mail mentions per death from communicable disease"
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
      screenCapture: tempCanvas.toDataURL()
      url: url
      title: title
    }), "*")
    tempCanvas.remove()

window.addEventListener("message", postMessageHandler, false)
