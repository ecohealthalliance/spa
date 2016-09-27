Highcharts = require('highcharts')
Template.reportingDelay.onCreated ->
  @reportingDelayStats = new Promise (resolve)->
    Meteor.call 'reportingDelayStats', (err, stats)->
      console.log stats
      console.error err
      resolve(stats)
Template.reportingDelay.onRendered ->
  @reportingDelayStats.then (stats)->
    Highcharts.chart(@$(".reporting-delay")[0], {
      title:
        text: 'Median Reporting Delay'
        x: -20
      xAxis:
        type: 'datetime'
      yAxis: [
        {
          title:
            text: 'Deplay (hours)'
          max: 100
        }
        {
          title:
            text: 'Number of articles'
          opposite: true
          max: 20000
        }
      ]
      plotLines: [{
        value: 0,
        width: 1,
        color: '#808080'
      }]
      tooltip:
        valueSuffix: ' hours'
      legend:
        layout: 'vertical'
        verticalAlign: 'top'
        borderWidth: 0
        align: 'left'
        x: 120
        y: 100
        floating: true
      series: [
        {
          name: 'Total Articles'
          data: _.map(stats.volume, (value, key)->[moment.utc(year: key).unix() * 1000, value])
          type: 'column'
          yAxis: 1
          tooltip:
            valueSuffix: ' articles'
        }
        {
          name: 'Single Article'
          data: _.map(stats.singleArticle, (value, key)->[moment.utc(year: key).unix() * 1000, value])
        }
        {
          name: 'Multiple Article'
          color: '#0000FF'
          data: _.map(stats.multipleArticle, (value, key)-> [moment.utc(year: key).unix() * 1000, value])
        }
      ]
    })