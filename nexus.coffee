http = require 'http'
urls = require 'url'
querystring = require 'querystring'

jade = require './vendor/jade'

riakdb = require('riak-js').getClient()

Canvas = require('canvas')
Image = Canvas.Image
csimage = new Image
circle =  new Image
bigcircle =  new Image

circle.onerr = (err) ->
  throw err
csimage.onerr = (err) ->
  throw err
bigcircle.onerr = (err) ->
  throw err

@csavail = false
csimage.onload = ->
  @csavail = true
circle.onload = ->
bigcircle.onload = ->


csimage.src = __dirname + '/cs.png'
circle.src  = __dirname + '/b.png'
bigcircle.src  = __dirname + '/BB2.png'

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
makeandblat { name: 'Dracula', player: 'Peter', virtue: 'Fortitude', vice: 'Pride', power: 3, power_type: "Gnosis", stats: ["Statblock", { pre: 4, com: 5, sta: 4 }], skills: { medicine: 2, occult: 4, investigation: 2, crafts: 5 , science: 3, athletics: 5, larceny: 2, stealth: 4, socialize: 2, streetwise: 3 }, arcana: { space: 2, spirit: 2, time: 2, fate: 2, matter: 2, death: 2 }, morality: {moral_amount: 8, moral_path: "Humanity" }, first_affiliation: "Path", second_affiliation: "Order", cabal: "ST Team", merits: [ ['Resources', 3], ['Fame', 4], ['Destiny', 1], ['Herd', 5], ['Haven', 2], ['Allies: Emos', 1] ], flaws: [ "Ammoniel: Severe", "Schizophrenia: Mild", "Nightmares: Severe" ], rote_skills: ["Computer", "Medicine", "Occult"], xp : 340 }
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




posgrid = {
  stats: {
    int: [ 568, 573 ]
    wit: [ 568, 625 ]
    res: [ 568, 678 ]
    str: [ 919, 572 ]
    dex: [ 919, 624 ]
    sta: [ 919, 677 ]
    pre: [1305, 572 ]
    man: [1305, 624 ]
    com: [1305, 678 ]
  }
  skills: {
    #mental: {
      academics:       [ 431, 853  ]
      computer:        [ 431, 892  ]
      crafts:          [ 431, 931  ]
      investigation:   [ 431, 970  ]
      medicine:        [ 431, 1009 ]
      occult:          [ 431, 1048 ]
      politics:        [ 431, 1087 ]
      science:         [ 431, 1126 ]
    #}
    #physical: {
      athletics:       [ 431, 1240 ]
      brawl:           [ 431, 1279 ]
      drive:           [ 431, 1318 ]
      firearms:        [ 431, 1357 ]
      larceny:         [ 431, 1396 ]
      stealth:         [ 431, 1435 ]
      survival:        [ 431, 1474 ]
      weaponry:        [ 431, 1513 ]
    #}
    #social: {
      'animal ken':    [ 431, 1601 ]
      empathy:         [ 431, 1640 ]
      expression:      [ 431, 1679 ]
      intimidation:    [ 431, 1718 ]
      persuasion:      [ 431, 1757 ]
      socialize:       [ 431, 1796 ]
      streetwise:      [ 431, 1835 ]
      subterfuge:      [ 431, 1874 ]
    #}
  }
  gnosis:    [ 1036, 1132 ]
  willpower: [ 1036, 921  ]
  health:    [ 1036, 827  ]
  arcana: {
    death:  [ 871, 1588 ]
    fate:   [ 871, 1620 ]
    forces: [ 871, 1650 ]
    life:   [ 871, 1682 ]
    mind:   [ 871, 1742 ]
    matter: [ 871, 1712 ]
    prime:  [ 871, 1773 ]
    space:  [ 871, 1804 ]
    spirit: [ 871, 1835 ]
    time:   [ 871, 1866 ]
  }
  wisdom:   [ 1378, 1512 ]
}

dotsStat  = (ctx, num, x, y) ->
  if num? and num >= 1
    for i in [1..num]
      ctx.drawImage(circle, x + ((circle.width - 1) * (i - 1)), y, circle.width, circle.height)

dotsSkill = (ctx, num, x, y) ->
  if num? and num >= 1
    for i in [1..num]
      ctx.drawImage(circle, x + ((circle.width) * (i - 1)), y, circle.width, circle.height)

dotWG     = (ctx, num, x, y) ->
  if num? and num >= 1
    for i in [1..num]
      ctx.drawImage(bigcircle, x + ((bigcircle.width + 13.75) * (i - 1)), y, bigcircle.width, bigcircle.height)

dotHealth = (ctx, num, x, y) ->
  if num? and num >= 1
    for i in [1..num]
      ctx.drawImage(bigcircle, x + ((bigcircle.width - 0.5) * (i - 1)), y, bigcircle.width, bigcircle.height)

# Unlike the others, this function starts from the top left of the bottom most dot.
dotWis    = (ctx, num, x, y) ->
  if num? and num >= 1
    for i in [1..num]
      ctx.drawImage(circle, x, y - ((circle.width + 8.5) * (i - 1)), circle.width, circle.height)

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


showCharsheetOld = (req, res, name) ->
  riakdb.get 'charsheets', name, (err, cs) ->
    if err
      fourohfour(req, res, 'image for character sheet for: ' + name)
    else
      canvas = new Canvas(csimage.width, csimage.height)
      ctx = canvas.getContext('2d')
      ctx.drawImage(csimage, 0, 0, csimage.width, csimage.height)
      ctx.setFont('medium', 'normal', 40, 'px', 'Glass TTY VT220')
      ctx.fillText cs.name, 300, 335
      ctx.font = '26px Impact, Liberation Bitstream Vera'
      ctx.fillText cs.size.toString(), 670, 1358
      flx = 0
      if cs.flaws?
        for flaw in cs.flaws
          ctx.fillText flaw, 615, 1238 + (41 * flx)
          flx++
      flx = 0
      if cs.merits?
        for merit in cs.merits
          ctx.fillText merit.name, 615, 869 + (38.5 * flx)
          dotsSkill ctx, merit.num, 870, 853 + (38.5 * flx)
          flx++
      ctx.font = '40px Impact, Liberation Bitstream Vera'
      if cs.player?
        ctx.fillText cs.player, 318,  394
      if cs.virtue?
        ctx.fillText cs.virtue, 840,  394
      if cs.vice?
        ctx.fillText cs.vice,   795,  449
      if cs.path?
        ctx.fillText cs.path,   1214, 334
     if cs.order?
        ctx.fillText cs.order,  1233, 397
     if cs.cabal?
        ctx.fillText cs.cabal,  1231, 453
     if cs.stats?
        dotHealth ctx, cs.stats.sta + cs.size, posgrid.health[0], posgrid.health[1]
        dotWG ctx, cs.stats.res + cs.stats.com, posgrid.willpower[0], posgrid.willpower[1]
        for k, v of posgrid.stats
          dotsStat(ctx, cs.stats[k], v[0], v[1])
      if cs.skills?
        for k, v of posgrid.skills
          dotsSkill(ctx, cs.skills[k], v[0], v[1])
      if cs.arcana?
        for k, v of posgrid.arcana
          dotsSkill(ctx, cs.arcana[k], v[0], v[1])
      if cs.gnosis?
        dotWG ctx, cs.gnosis, posgrid.gnosis[0],  posgrid.gnosis[1]
      if cs.wisdom?
        dotWis ctx, cs.wisdom, posgrid.wisdom[0],  posgrid.wisdom[1]
      buf = canvas.toBuffer()
      res.writeHeader 200, 'Content-Type': 'image/png'
      buf2 = new Buffer(buf.length)
      buf.copy(buf2, 0, 0)
      res.end(buf2)

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
