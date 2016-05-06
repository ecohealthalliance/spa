Meteor.methods
  aggregateMentionsOverDateRange: (startDate, endDate, feeds)->
    console.log feeds
    result = Posts.aggregate([
      {
        "$match": {
          "subject.ns1": { "$in": feeds },
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
