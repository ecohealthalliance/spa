module.exports =
  round: (num, positions)->
    magnitude = Math.pow(10, positions)
    Math.round(magnitude * num) / magnitude
  # These take a javascript datetimes and truncate the time component so that it
  # is either the start or end of the day respectively.
  truncateDateToStart: (d)->
    d.setHours(0)
    d.setMinutes(0)
    d.setSeconds(0)
    d
  truncateDateToEnd: (d)->
    d.setHours(23)
    d.setMinutes(59)
    d.setSeconds(59)
    d
  addCommas: (num)->
    num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")

UI.registerHelper 'addCommas', module.exports.addCommas
