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
    sliderEl.noUiSlider.on 'update', (values, handle)=>
      $adjustRangeEl = $('.noUI-adjustRange')
      sliderEl.dispatchEvent(new Event('update'))
      rangeWidth = $('.noUi-draggable').width() - $('.noUi-origin.noUi-background').width()
      $adjustRangeEl.css 'left', rangeWidth / 2
      if rangeWidth < $('.noUi-base').width() - 5
        $adjustRangeEl.removeClass 'hidden'
      else
        $adjustRangeEl.addClass 'hidden'

    $('.noUi-draggable').append '<span class="noUI-adjustRange hidden"></span>'
