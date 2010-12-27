# This file populates a riak datastore with some default character sheet data

http = require 'http'
urls = require 'url'
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

makeandblat { name: 'Dracula', player: 'Peter', virtue: 'Fortitude', vice: 'Pride', power: 3, power_type: "Gnosis", stats: ["Statblock", { dex: 3, pre: 4, com: 5, sta: 4 }], skills: { medicine: 2, occult: 4, investigation: 2, crafts: 5 , science: 3, athletics: 5, larceny: 2, stealth: 4, socialize: 2, streetwise: 3 }, arcana: { space: 2, spirit: 2, time: 2, fate: 2, matter: 2, death: 2 }, morality: {moral_amount: 8, moral_path: "Humanity" }, first_affiliation: "Path", second_affiliation: "Order", cabal: "ST Team", merits: [ ['Resources', 3], ['Fame', 4], ['Destiny', 1], ['Herd', 5], ['Haven', 2], ['Allies: Emos', 1] ], flaws: [ "Ammoniel: Severe", "Schizophrenia: Mild", "Nightmares: Severe" ], rote_skills: ["Computer", "Medicine", "Occult"], xp : 110, xp_total: 500 }

