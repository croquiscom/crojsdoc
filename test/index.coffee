fs = require 'fs'

describe 'CoffeeScript', ->
  fs.readdirSync(__dirname + '/coffee').forEach (filename) ->
    return if not /\.coffee$/.test filename
    require "./coffee/#{filename}"

describe 'JavaScript', ->
  fs.readdirSync(__dirname + '/js').forEach (filename) ->
    return if not /\.coffee$/.test filename
    require "./js/#{filename}"

describe 'TypeScript', ->
  fs.readdirSync(__dirname + '/ts').forEach (filename) ->
    return if not /\.coffee$/.test filename
    require "./ts/#{filename}"

describe 'tags', ->
  fs.readdirSync(__dirname + '/tags').forEach (filename) ->
    return if not /\.coffee$/.test filename
    require "./tags/#{filename}"

describe 'unit', ->
  fs.readdirSync(__dirname + '/unit').forEach (filename) ->
    return if not /\.coffee$/.test filename
    require "./unit/#{filename}"
