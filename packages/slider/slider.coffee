Template.slider.onCreated ->
  @sliderMin = @data?.sliderMin
  @sliderMax = @data?.sliderMax
Template.slider.onRendered ->
  slider = null
  sliderEl = @$("#slider")[0]
  @autorun =>
    if slider
      slider.destroy()
    slider = noUiSlider.create(sliderEl, {
    	start: [ @sliderMin.get(), @sliderMax.get() ]
    	step: 1
    	behaviour: 'drag'
    	connect: true
    	range:
    		'min':  @sliderMin.get()
    		'max':  @sliderMax.get()
    })
    sliderEl.noUiSlider.on('update', (values, handle)=>
      sliderEl.dispatchEvent(new Event('update'))
    )
