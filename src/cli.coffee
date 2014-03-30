fs = require 'fs'
optparse = require 'optparse'
path = require 'path'
yaml = require 'js-yaml'

options =
  project_dir: process.cwd()

switches = [
  [ '-o', '--output DIRECTORY', 'Output directory' ]
  [ '-t', '--title TITLE', 'Document Title' ]
  [ '-q', '--quite', 'less output' ]
  [ '-r', '--readme DIRECTORY', 'README.md directory path']
  [ '-f', '--files', 'included source files' ]
  [ '--external-types JSONFILE', 'external type definitions' ]
]
parser = new optparse.OptionParser switches
parser.on '*', (opt, value) ->
  if value is undefined
    value = true
  options[opt] = value
paths = parser.parse process.argv.slice 2

try
  config = yaml.safeLoad fs.readFileSync(path.join(process.cwd(), 'crojsdoc.yaml'), 'utf-8')
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
catch e

options.output_dir = path.resolve options.project_dir, options.output or 'doc'

# Links for pre-known types
options.types =
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

if external_types = options['external-types']
  if typeof external_types is 'string'
    try
      content = fs.readFileSync(external_types, 'utf-8').trim()
      try
        external_types = JSON.parse content
      catch e
        console.log "external-types: Invalid JSON file"
    catch e
      console.log "external-types: Cannot open #{options['external-types']}"
  if typeof external_types is 'object'
    for type, url of external_types
      options.types[type] = url

result = require('./collect') paths, options
require('./render') result, options
