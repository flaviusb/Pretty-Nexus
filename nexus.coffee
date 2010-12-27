http = require 'http'
urls = require 'url'
querystring = require 'querystring'

jade = require './vendor/jade'

riakdb = require('riak-js').getClient()

merge = (src, dest) ->
  if src instanceof Array
    if dest instanceof Array and src[0] is "Statblock"
      dest[1] = merge src[1], dest[1]
    else
      dest = src
  for i, j of src
    if j instanceof Object and dest[i]?
      dest[i] = merge j, dest[i]
    else
      dest[i] = j
  return dest
       
makecharsheet = (override, todo) ->
  riakdb.get 'charsheets', 'default', (err, blank) ->
    blank = merge override, blank
    todo(blank)

makeandsave = (override) ->
  makecharsheet override, (sheet) ->
    riakdb.save('charsheets', sheet.name, sheet)

makeandblat = (override) ->
  if override.name?
    riakdb.remove 'charsheets', override.name
  makeandsave override

###
# Example for saving raw charactersheet data to the riak datastore:
riakdb.save('charsheets', 'default', { name: '', size: 5, stats: ["Statblock", { str: 2, dex: 2, sta: 2, int: 2, wit: 2, res: 2, pre: 2, man: 2, com: 2  }], skills: {  } })

# Example for makeandblat:
makeandblat { name: 'Dracula', player: 'Peter', virtue: 'Fortitude', vice: 'Pride', power: 3, power_type: "Gnosis", stats: ["Statblock", { dex: 3, pre: 4, com: 5, sta: 4 }], skills: { medicine: 2, occult: 4, investigation: 2, crafts: 5 , science: 3, athletics: 5, larceny: 2, stealth: 4, socialize: 2, streetwise: 3 }, arcana: { space: 2, spirit: 2, time: 2, fate: 2, matter: 2, death: 2 }, morality: {moral_amount: 8, moral_path: "Humanity" }, first_affiliation: "Path", second_affiliation: "Order", cabal: "ST Team", merits: [ ['Resources', 3], ['Fame', 4], ['Destiny', 1], ['Herd', 5], ['Haven', 2], ['Allies: Emos', 1] ], flaws: [ "Ammoniel: Severe", "Schizophrenia: Mild", "Nightmares: Severe" ], rote_skills: ["Computer", "Medicine", "Occult"], xp : 110, xp_total: 500 }
###

# This is my routing microframework. Until stuff stabilises with other frameworks, I'll just use this.
choose_path = (req, res, routes) ->
  url = urls.parse(req.url).pathname
  for [i, j] in routes
    it = i(url)
    if it
      j(req, res, it[1..])
      break


index = (req, res) ->
  res.writeHeader 200, 'Content-Type': 'text/html'
  options = locals: {}
  jade.renderFile __dirname + "/index.jade", options, (error, data) ->
    res.write data
    res.end()

fourohfour = (req, res, url) ->
  res.writeHeader 404, 'Content-Type': 'text/html'
  options = locals: { url: url }
  jade.renderFile __dirname + "/404.jade", options, (error, data) ->
    res.end data

editdone = (req, res, url) ->
  res.writeHeader 200, 'Content-Type': 'text/html'
  options = locals: { url: url }
  jade.renderFile __dirname + "/done.jade", options, (error, data) ->
    res.end data

getCharsheet = (req, res, name) ->
  riakdb.get 'charsheets', name, (err, cs) ->
    if err
      fourohfour(res, 'character sheet for: ' + name)
    else
      res.writeHeader 200, 'Content-Type': 'application/xml'
      jade.renderFile __dirname + "/charsheet.jade", { locals: cs }, (error, data) ->
        res.end data

getJSONCharsheet = (req, res, name) ->
  riakdb.get 'charsheets', name, (err, cs) ->
    if err
      fourohfour(res, 'character sheet for: ' + name)
    else
      res.writeHeader 200, 'Content-Type': 'application/json'
      res.end JSON.stringify(cs)


editCharsheet = (req, res, name) ->
  riakdb.get 'charsheets', name, (err, cs) ->
    if err
      fourohfour(res, 'character sheet for: ' + name)
    else
      src = querystring.parse(urls.parse(req.url).query)
      console.log src
      newcs = merge src, cs
      makeandblat newcs
      editdone req, res, name


ocamlserver = http.createClient 9999, '127.0.0.1'
showCharsheetPng = (req, res, name) ->
  riakdb.get 'charsheets', name, (err, cs) ->
    if err
      fourohfour(req, res, 'image for character sheet for: ' + name)
    else
      #console.log (querystring.escape ("cs="+JSON.stringify(cs)))
      foo =  (JSON.stringify(cs))
      request = ocamlserver.request 'POST', '/png', { host: 'localhost', 'content-type': 'application/x-www-form-urlencoded', 'content-length': foo.length}
      request.write foo
      request.end()
      res.writeHeader 200, 'Content-Type': 'image/png'
      request.on 'response', (response) ->
        response.setEncoding 'base64'
        response.on 'data', (chunk) ->
          buf = new Buffer(chunk, 'base64')
          res.write buf
        response.on 'end', () ->
          res.end()
showCharsheetPdf = (req, res, name) ->
  riakdb.get 'charsheets', name, (err, cs) ->
    if err
      fourohfour(req, res, 'pdf for character sheet for: ' + name)
    else
      #console.log (querystring.escape ("cs="+JSON.stringify(cs)))
      foo =  (JSON.stringify(cs))
      request = ocamlserver.request 'POST', '/pdf', { host: 'localhost', 'content-type': 'application/x-www-form-urlencoded', 'content-length': foo.length}
      request.write foo
      request.end()
      res.writeHeader 200, 'Content-Type': 'application/pdf'
      request.on 'response', (response) ->
        response.setEncoding 'base64'
        response.on 'data', (chunk) ->
          buf = new Buffer(chunk, 'base64')
          res.write buf
        response.on 'end', () ->
          res.end()


myRoutes = [
  [ /^\/editcharsheet\/([a-zA-Z]*)$/, editCharsheet ]
  [ /^\/charsheet\/([a-zA-Z]*)[.\/]xml$/, getCharsheet ]
  [ /^\/charsheet\/([a-zA-Z]*)[.\/]json$/, getJSONCharsheet ]
  [ /^\/charsheet\/([a-zA-Z]*)[.\/]png$/, showCharsheetPng ]
  [ /^\/charsheet\/([a-zA-Z]*)[.\/]pdf$/, showCharsheetPdf ]
  [ /^\/$/, index ]
  [ /^(.*)$/, fourohfour ]
]


server = http.createServer (req, res) ->
  choose_path(req, res, myRoutes)

server.listen 3000

console.log "Server running at http://localhost:3000/"
