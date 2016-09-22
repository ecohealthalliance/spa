Meteor.startup ->
  Posts._ensureIndex({ "subject.raw": "text" })

Picker.route '/api/v1/search', (params, request, response, next) ->
  query = params.query
  searchText = query.text

  response.setHeader('Content-Type', 'application/json')

  unless searchText
    response.statusCode = 401
    response.end JSON.stringify { error: "No search text provided" }

  posts = Posts.find({
    $text: { $search: searchText }
  }, {
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

Picker.route '/api/v1/find', (params, request, response, next) ->
  query = params.query
  mongoQuery = query.q

  response.setHeader('Content-Type', 'application/json')

  unless mongoQuery
    response.statusCode = 401
    response.end JSON.stringify { error: "No query provided" }

  queryObject = JSON.parse mongoQuery

  posts = Posts.find(queryObject, {
    fields: { 'promedId': true, 'subject.raw': true  }
    limit: 5
  }).fetch()

  response.statusCode = 200
  response.setHeader('Content-Type', 'application/json')
  response.end JSON.stringify posts
