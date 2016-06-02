Meteor.methods
  aggregateMentionsOverDateRange: ({startDate, endDate, feedIds})->
    result = Posts.aggregate([
      {
        "$match": {
          "feedId": { "$in": feedIds }
          "$and": [
            {
              "promedDate": { "$gte": startDate }
            },
            {
              "promedDate": { "$lte": endDate }
            }
          ]
        }
      },
      { "$unwind": "$articles" },
      { "$unwind": "$articles.geoannotations" },
      {
        "$group": {
          "_id": "$articles.geoannotations.country code",
          "mentions": { "$sum": 1 }
        }
      }
    ])
    return _.object(result.map((country)->
      [country._id, country.mentions]
    ))
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
