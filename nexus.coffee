http = require 'http'
urls = require 'url'
querystring = require 'querystring'

jade = require './vendor/jade'

riakdb = require('riak-js').getClient()

riakdb.save('charsheets', 'default', { name: '', size: 5, stats: ["Statblock", { str: 2, dex: 2, sta: 2, int: 2, wit: 2, res: 2, pre: 2, man: 2, com: 2  }], skills: {  } })

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
makeandblat { name: 'Dracula', player: 'Peter', virtue: 'Fortitude', vice: 'Pride', gnosis: 3, stats: { pre: 4, com: 5, sta: 4 }, skills: { blah: 4, medicine: 2, occult: 4, investigation: 2, crafts: 5 , science: 3, athletics: 5, larceny: 2, stealth: 4, socialize: 2, streetwise: 3 }, flaws: [ "Numerophobia: Mild" ], merits: [ { name: 'Striking Looks', num: 2 }, { name: 'Resources', num: 3 } ], arcana: { space: 2, spirit: 2, time: 2, fate: 2, matter: 2, death: 2 }, wisdom: 8 }
makeandblat { name: 'Longinus', player: 'Patrick', virtue: 'n/a', vice: 'All seven', gnosis: 6, stats: { int: 5, res: 4, sta: 1, man: 3 }, skills: { academics: 4, investigation: 1, computer: 5, politics: 1 , brawl: 5, drive: 2, firearms: 5, intimidation: 5, persuasion: 2 }, flaws: [ "Ammoniel: Severe", "Schizophrenia: Mild", "Nightmares: Severe" ], merits: [ { name: 'Destiny', num: 5 }, { name: 'Status', num: 3 }, { name: 'Contacts', num: 1 }, { name: 'Allies: Angelic', num: 5 }, { name: 'Fame', num: 5 } ], cabal: 'Lancea Sanctum', path: 'Mastigos/Obrimos', order: 'Unaligned', arcana: { mind: 4, death: 1, prime: 2, forces: 5 }, wisdom: 3 }
makeandblat { name: 'Remus', player: 'Jason', virtue: 'Prudence', vice: 'Lust', gnosis: 4, size: 6, stats: { int: 3, res: 5, sta: 5, man: 4, com: 5 }, skills: { academics: 4, investigation: 1, computer: 5, politics: 1 , survival: 5, weaponry: 3, 'animal ken': 1, empathy: 4, subterfuge: 5 }, flaws: [ "Aluriophobia: Severe" ], arcana: { life: 2, forces: 2 }, wisdom: 6  }
###
makeandblat { name: 'Dracula', player: 'Peter', virtue: 'Fortitude', vice: 'Pride', power: 3, power_type: "Gnosis", stats: ["Statblock", { dex: 3, pre: 4, com: 5, sta: 4 }], skills: { medicine: 2, occult: 4, investigation: 2, crafts: 5 , science: 3, athletics: 5, larceny: 2, stealth: 4, socialize: 2, streetwise: 3 }, arcana: { space: 2, spirit: 2, time: 2, fate: 2, matter: 2, death: 2 }, morality: {moral_amount: 8, moral_path: "Humanity" }, first_affiliation: "Path", second_affiliation: "Order", cabal: "ST Team", merits: [ ['Resources', 3], ['Fame', 4], ['Destiny', 1], ['Herd', 5], ['Haven', 2], ['Allies: Emos', 1] ], flaws: [ "Ammoniel: Severe", "Schizophrenia: Mild", "Nightmares: Severe" ], rote_skills: ["Computer", "Medicine", "Occult"], xp : 110, xp_total: 500 }
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
