recomputePostsDateRange = ->
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
postDateRange = recomputePostsDateRange()
# Update postDateRange hourly
setInterval(->
  console.log "Updating postDateRange"
  postDateRange = recomputePostsDateRange()
, 60 * 1000 * 60)

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
    return postDateRange
  trendingCountries: ({startDate, recentCutoffDate, feedIds})->
    endDate = postDateRange[1]
    result = Posts.aggregate([
      {
        "$match": {
          "feedId": { "$in": feedIds },
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
      {
        "$project": {
          "articles.geoannotations": 1,
          "recent": {
            "$gte": ["$promedDate", recentCutoffDate]
          }
        }
      },
      { "$unwind": "$articles.geoannotations" },
      {
        "$group": {
          "_id": "$articles.geoannotations.country code",
          "mentions": { "$sum": 1 },
          "recentMentions": { "$sum": { "$cond": ["$recent", 1, 0] } }
        }
      }
    ])
    return _.object(result.map(({_id, mentions, recentMentions})->
      mentionFrequency = mentions / (endDate - startDate)
      recentMentionFrequency = recentMentions / (endDate - recentCutoffDate)
      return [
        _id
        recentMentionFrequency - mentionFrequency
      ]
    ))
