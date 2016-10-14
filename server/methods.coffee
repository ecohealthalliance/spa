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
  if result?[0]
    return [result[0].startDate, result[0].endDate]

postDateRange = recomputePostsDateRange()

# Update postDateRange hourly
Meteor.setInterval(->
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
  reportingDelayStats: ->
    result = Posts.aggregate([
      {
        "$project":
          "numArticles": "$size": "$articles"
          "articles": 1
          "promedDate": 1
      }
      { "$unwind": "$articles" }
      {
        "$match":
          "promedDate": "$ne": null
          "articles.date": "$ne": null
      }
      {
        "$project":
          "delayHours":
            "$divide": [
              {
                "$subtract": [
                  "$promedDate"
                  "$articles.date"
                ]
              }
              # 1 hour is ms
              1000 * 60 * 60
            ]
          "year": "$year": "$promedDate"
          "numArticles": 1
      }
    ])
    return {
      singleArticle: _.chain(result.filter((d)->d.numArticles == 1))
        .groupBy (d)->d.year
        .pairs()
        .map(([key, val])->[key, math.median(val.map((d)->d.delayHours))])
        .object()
        .value()
      multipleArticle: _.chain(result.filter((d)->d.numArticles > 1))
        .groupBy (d)->d.year
        .pairs()
        .map(([key, val])->[key, math.median(val.map((d)->d.delayHours))])
        .object()
        .value()
      volume: _.chain(result)
        .groupBy (d)->d.year
        .pairs()
        .map(([key, val])->[key, val.length])
        .object()
        .value()
    }
