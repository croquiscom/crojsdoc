fs = require 'fs'
path = require 'path'

readConfig = (options, paths) ->
  {safeLoad} = require 'js-yaml'
  try
    config = safeLoad fs.readFileSync(path.join(process.cwd(), 'crojsdoc.yaml'), 'utf-8')
    if config.hasOwnProperty 'output'
      options.output = config.output
    if config.hasOwnProperty 'title'
      options.title = config.title
    if config.hasOwnProperty 'quite'
      options.quite = config.quite is true
    if  config.hasOwnProperty 'files'
      options.files = config.files is true
    if config.hasOwnProperty('readme') and typeof config.readme is 'string'
      options.readme = config.readme
    if config.hasOwnProperty 'external-types'
      options['external-types'] = config['external-types']
    if config.hasOwnProperty 'sources'
      if Array.isArray config.sources
        [].push.apply paths, config.sources
      else
        paths.push config.sources
    if config.hasOwnProperty 'github'
      options.github = config.github
      if options.github.branch is undefined
        options.github.branch = 'master'

parseArguments = (options, paths) ->
  {OptionParser} = require 'optparse'
  switches = [
    [ '-o', '--output DIRECTORY', 'Output directory' ]
    [ '-t', '--title TITLE', 'Document Title' ]
    [ '-q', '--quite', 'less output' ]
    [ '-r', '--readme DIRECTORY', 'README.md directory path']
    [ '-f', '--files', 'included source files' ]
    [ '--external-types JSONFILE', 'external type definitions' ]
  ]
  parser = new OptionParser switches
  parser.on '*', (opt, value) ->
    if value is undefined
      value = true
    options[opt] = value
  [].push.apply paths, parser.parse process.argv.slice 2

readExternalTypes = (external_types, types) ->
  return if not external_types

  if typeof external_types is 'string'
    try
      content = fs.readFileSync(external_types, 'utf-8').trim()
      try
        external_types = JSON.parse content
      catch e
        console.log "external-types: Invalid JSON file"
    catch e
      console.log "external-types: Cannot open #{external_types}"

  if typeof external_types is 'object'
    for type, url of external_types
      types[type] = url

getOptionsAndPaths = ->
  options =
    project_dir: process.cwd()
    types:
      # Links for pre-known types
      Object: 'https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Object'
      Boolean: 'https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Boolean'
      String: 'https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'
      Array: 'https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array'
      Number: 'https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Number'
      Date: 'https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Date'
      Function: 'https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Function'
      RegExp: 'https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/RegExp'
      Error: 'https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Error'
      undefined: 'https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/undefined'
  paths = []

  readConfig options, paths
  parseArguments options, paths
  readExternalTypes options['external-types'], options.types

  options.output_dir = path.resolve options.project_dir, options.output or 'doc'

  return [options, paths]

[options, paths] = getOptionsAndPaths()
result = require('./collect') paths, options
require('./render') result, options
