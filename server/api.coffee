Meteor.startup ->
  Posts._ensureIndex({ "subject.raw": "text" })

Picker.route '/api/v1/search', (params, request, response, next) ->
  query = params.query
  searchText = query.text
  notOneOfThese = query.not?.split(' ')

  response.setHeader('Content-Type', 'application/json')

  unless searchText
    response.statusCode = 401
    response.end JSON.stringify { error: "No search text provided" }

  mongoQuery = {
    $text: { $search: searchText }
  }

  if notOneOfThese?.length
    mongoQuery.promedId = { $nin: notOneOfThese }

  posts = Posts.find(mongoQuery, {
    fields:
      promedId: true
      'subject.raw': true
      score: { $meta: "textScore" }
    limit: 5
    sort:
      score: { $meta: "textScore" }
  }).fetch()

  response.statusCode = 200
  response.setHeader('Content-Type', 'application/json')
  response.end JSON.stringify posts
