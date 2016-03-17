Template.slider.onCreated ->
  @sliderMin = @data?.sliderMin
  @sliderMax = @data?.sliderMax
Template.slider.onRendered ->
  slider = null
  sliderEl = @$("#slider")[0]
  formatValue = (v)->
    if v.getTime
      v.getTime()
    else
      v
  @autorun =>
    if slider
      slider.destroy()
    formattedMin = formatValue @sliderMin.get()
    formattedMax = formatValue @sliderMax.get()
    slider = noUiSlider.create(sliderEl, {
    	start: [ formattedMin, formattedMax ]
    	behaviour: 'drag'
    	connect: true
    	range:
    		'min':  formattedMin
    		'max':  formattedMax
    })
    sliderEl.noUiSlider.on('update', (values, handle)=>
      sliderEl.dispatchEvent(new Event('update'))
    )
