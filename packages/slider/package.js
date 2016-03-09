Package.describe({
  name: 'eha:slider',
  version: '0.0.2',
  summary: 'A slider component based on noUiSlider',
  documentation: 'README.md'
});

Package.onUse(function(api) {
  api.versionsFrom('1.2.1');
  api.use('markoshust:nouislider');
  api.use('coffeescript');
  api.use('templating');
  api.use('reactive-var');
  api.addFiles('slider.html', 'client');
  api.addFiles('slider.coffee', 'client');
});
