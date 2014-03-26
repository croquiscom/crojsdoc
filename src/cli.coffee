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

require('./generate') paths, options
