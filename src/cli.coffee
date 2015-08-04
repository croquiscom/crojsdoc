##
# Provides CroJSDoc command line interface
# @module cli

fs = require 'fs'
glob = require 'glob'
walkdir = require 'walkdir'
{basename,dirname,join,resolve} = require 'path'

isWindows = process.platform is 'win32'

##
# Reads a config file(crojsdoc.yaml) to build options
# @param {Options} options
# @memberOf cli
# @private
_readConfig = (options) ->
  {safeLoad} = require 'js-yaml'
  try
    config = safeLoad fs.readFileSync(join(process.cwd(), 'crojsdoc.yaml'), 'utf-8')
    if config.hasOwnProperty 'output'
      options.output = config.output
    if config.hasOwnProperty 'title'
      options.title = config.title
    if config.hasOwnProperty 'quite'
      options.quite = config.quite is true
    if  config.hasOwnProperty 'files'
      options.files = config.files is true
    if config.hasOwnProperty('readme') and typeof config.readme is 'string'
      options._readme = config.readme
    if config.hasOwnProperty 'external-types'
      options['external-types'] = config['external-types']
    if config.hasOwnProperty 'sources'
      if Array.isArray config.sources
        [].push.apply options._sources, config.sources
      else
        options._sources.push config.sources
    if config.hasOwnProperty 'github'
      options.github = config.github
      if options.github.branch is undefined
        options.github.branch = 'master'
    if config.hasOwnProperty 'reverse_see_also'
      options.reverse_see_also = config.reverse_see_also is true
    if config.hasOwnProperty 'plugins'
      plugins = config.plugins
      if not Array.isArray plugins
        plugins = [plugins]
      options.plugins = plugins.map (plugin) ->
        try
          require plugin
        catch e
          console.log "Plugin '#{plugin}' not found"
      .filter (plugin) -> plugin
    return

##
# Parses the command line arguments to build options
# @param {Options} options
# @memberOf cli
# @private
_parseArguments = (options) ->
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
  [].push.apply options._sources, parser.parse process.argv.slice 2

##
# Reads additional type definitions from a file or a object
# @param {String|Object} external_types
# @param {Object} types
# @memberOf cli
# @private
_readExternalTypes = (external_types, types) ->
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

##
# Builds options from a config file(crojsdoc.yaml) or command line arguments
# @return {Options}
# @memberOf cli
# @private
_buildOptions = ->
  options =
    _project_dir: process.cwd()
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
    _sources: []

  _readConfig options
  _parseArguments options
  _readExternalTypes options['external-types'], options.types

  options.output_dir = resolve options._project_dir, options.output or 'doc'

  return options

##
# Reads source files
# @param {Options} options
# @return {Array<Content>}
# @memberOf cli
# @private
_readSourceFiles = (options) ->
  if isWindows
    project_dir_re = new RegExp("^" + options._project_dir.replace(/\\/g, '\\\\'))
  else
    project_dir_re = new RegExp("^" + options._project_dir)
  contents = []
  for path in options._sources
    base_path = path = resolve options._project_dir, path
    base_path = dirname base_path while /[*?]/.test basename(base_path)
    glob.sync(path).forEach (path) =>
      if fs.statSync(path).isDirectory()
        list = walkdir.sync path
      else
        list = [path]
      for file in list
        continue if fs.statSync(file).isDirectory()
        data = fs.readFileSync(file, 'utf-8').trim()
        continue if not data
        if isWindows
          contents.push path: file.replace(project_dir_re, '').replace(/\\/g, '/'), file: file.substr(base_path.length+1).replace(/\\/g, '/'), data: data
        else
          contents.push path: file.replace(project_dir_re, ''), file: file.substr(base_path.length+1), data: data
      return
  try
    data = fs.readFileSync "#{options._readme or options._project_dir}/README.md", 'utf-8'
    contents.push path: '', file: 'README', data: data
  return contents

##
# Runs CroJSDoc via CLI
# @memberOf cli
exports.run = ->
  options = _buildOptions()
  contents = _readSourceFiles options
  result = require('./collect') contents, options
  require('./render') result, options
