http = require 'http'
urls = require 'url'

jade = require './vendor/jade'

riakdb = require('riak-js').getClient()

Canvas = require('canvas')
Image = Canvas.Image
csimage = new Image
circle =  new Image

circle.onerr = (err) ->
  throw err
csimage.onerr = (err) ->
  throw err

@csavail = false
csimage.onload = ->
  @csavail = true
circle.onload = ->


csimage.src = __dirname + '/cs.png'
circle.src  = __dirname + '/b.png'

riakdb.save('charsheets', 'default', { name: '', stats: { str: 2, dex: 2, sta: 2, int: 2, wit: 2, res: 2, pre: 2, man: 2, com: 2  }, skills: {  } })

merge = (src, dest) ->
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

makeandblat { name: 'Dracula',  stats: { pre: 5, com: 5 }, skills: { blah: 4, medicine: 2, occult: 4, investigation: 2, crafts: 5 , science: 3 } }
makeandblat { name: 'Longinus', stats: { int: 5, res: 4, sta: 1, man: 3 }, skills: { academics: 4, investigation: 1, computer: 5, politics: 1 } }

# This is my routing microframework. Until stuff stabilises with other frameworks, I'll just use this.
choose_path = (url, res, routes) ->
  foo = url.url
  for [i, j] in routes
    it = i(foo)
    if it
      j(res, it[1..])
      break


index = (res) ->
  res.writeHeader 200, 'Content-Type': 'text/html'
  options = locals: {}
  jade.renderFile __dirname + "/index.jade", options, (error, data) ->
    res.write data
    res.end()

fourohfour = (res, url) ->
  res.writeHeader 404, 'Content-Type': 'text/html'
  options = locals: { url: url }
  jade.renderFile __dirname + "/404.jade", options, (error, data) ->
    res.write data
    res.end()


getCharsheet = (res, name) ->
  #options = locals: { name: 'foo', stats: { str: 2, dex: 2, sta: 3  } }
  riakdb.get 'charsheets', name, (err, cs) ->
    if err
      fourohfour(res, 'character sheet for: ' + name)
    else
      res.writeHeader 200, 'Content-Type': 'application/xml'
      jade.renderFile __dirname + "/charsheet.jade", { locals: cs }, (error, data) ->
        res.write data
        res.end()

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
    # athletics:
    # brawl:
    # drive:
    # firearms:
    # larceny:
    # stealth:
    # survival:
    # weaponry:
    #}
    #social: {
    # 'animal Ken':
    # empathy:
    # expression:
    # intimidation:
    # persuasion:
    # socialize:
    # streetwise:
    # subterfuge:
    #}
  }
}

dotsStat = (ctx, num, x, y) ->
  if num? and num >= 1
    for i in [1..num]
      ctx.drawImage(circle, x + ((circle.width - 1) * (i - 1)), y, circle.width, circle.height)

dotsSkill = (ctx, num, x, y) ->
  if num? and num >= 1
    for i in [1..num]
      ctx.drawImage(circle, x + ((circle.width) * (i - 1)), y, circle.width, circle.height)

showCharsheet = (res, name) ->
  riakdb.get 'charsheets', name, (err, cs) ->
    if err
      fourohfour(res, 'image for character sheet for: ' + name)
    else
      canvas = new Canvas(csimage.width, csimage.height)
      ctx = canvas.getContext('2d')
      ctx.drawImage(csimage, 0, 0, csimage.width, csimage.height)
      ctx.font = '40px Impact, Liberation Bitstream Vera'
      ctx.fillText cs.name, 300, 335
      if cs.stats?
        for k, v of posgrid.stats
          dotsStat(ctx, cs.stats[k], v[0], v[1])
      if cs.skills?
        for k, v of posgrid.skills
          dotsSkill(ctx, cs.skills[k], v[0], v[1])
      buf = canvas.toBuffer()
      res.writeHeader 200, 'Content-Type': 'image/png'
      buf2 = new Buffer(buf.length)
      buf.copy(buf2, 0, 0)
      res.end(buf2)

myRoutes = [
  [ /^\/charsheet\/([a-zA-Z]*)[.\/]xml$/, getCharsheet ]
  [ /^\/charsheet\/([a-zA-Z]*)[.\/]png$/, showCharsheet ]
  [ /^\/$/, index ]
  [ /^(.*)$/, fourohfour ]
]


server = http.createServer (req, res) ->
  choose_path(req, res, myRoutes)

server.listen 3000

console.log "Server running at http://localhost:3000/"
