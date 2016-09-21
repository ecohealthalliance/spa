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
