Meteor.methods
  aggregateMentionsOverYearRange: (startYear, endYear)->
    countries = {}
    Blindspots.find(
      $and: [
        {
          year:
            $gte: startYear
        }
        {
          year:
            $lt: endYear
        }
      ]
    ).map (countryInYear)->
      unless countries[countryInYear.ISO]
        countries[countryInYear.ISO] = {name: countryInYear.Country, mentions: 0}
      countries[countryInYear.ISO].mentions += countryInYear.mentions
      countries[countryInYear.ISO].population = countryInYear.Population
      countries[countryInYear.ISO].mentionsPerCapita = countries[countryInYear.ISO].mentions / countries[countryInYear.ISO].population
    return countries
  getPostsDateRange: ->
    result = Posts.aggregate([
      {
        $group:
          _id: null
          startDate:
            $min: "$promedDate"
          endDate:
            $max: "$promedDate"
      }
    ])
    return [result[0].startDate, result[0].endDate]
