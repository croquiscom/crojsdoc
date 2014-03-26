##
# @module render

fs = require 'fs'
jade = require 'jade'
markdown = require 'marked'
{resolve} = require 'path'

##
# Renderer
class Renderer
  constructor: (@result, @genopts) ->
    @output_dir = resolve genopts.project_dir, genopts.output or 'doc'

    theme = 'default'
    @resources_dir = resolve __dirname, '../themes', theme, 'resources'
    @templates_dir = resolve __dirname, '../themes', theme, 'templates'

    # Links for pre-known types
    @types =
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

    if external_types = genopts['external-types']
      if typeof external_types is 'string'
        try
          content = fs.readFileSync(external_types, 'utf-8').trim()
          try
            external_types = JSON.parse content
          catch e
            console.log "external-types: Invalid JSON file"
        catch e
          console.log "external-types: Cannot open #{genopts['external-types']}"
      if typeof external_types is 'object'
        for type, url of external_types
          @types[type] = url

  ##
  # @private
  # @param {String} type
  # @return {String}
  makeMissingLink: (type, place = '') ->
    txt = if @result.ids[type]
      "'#{type}' link is ambiguous"
    else
      "'#{type}' link does not exist"
    console.log txt + " #{place}"
    return "<span class='missing-link'>#{type}</span>"

  ##
  # Makes links for given type
  #
  # * "String" -&gt; "&lt;a href='reference url for String'&gt;String&lt;/a&gt;"
  # * "Array&lt;Model&gt;" -&gt; "&lt;a href='reference url for Array'&gt;Array&lt;/a&gt;&amp;lt;&lt;a href='internal url for Model'&gt;Model&lt;/a&gt;&amp;gt;"
  # @private
  # @param {String} rel_path
  # @param {String} type
  # @return {String}
  makeTypeLink: (rel_path, type, place = '') ->
    return type if not type
    getlink = (type) =>
      if @types[type]
        link = @types[type]
      else if @result.ids[type] and @result.ids[type] isnt 'DUPLICATED ENTRY'
        filename = @result.ids[type].filename + '.html'
        html_id = @result.ids[type].html_id
        link = "#{rel_path}#{filename}##{html_id}"
      else
        return @makeMissingLink type, place
      return "<a href='#{link}'>#{type}</a>"
    if res = type.match(/\[(.*)\]\((.*)\)/)
      @types[res[1]] = res[2]
      return "<a href='#{res[2]}'>#{res[1]}</a>"
    if res = type.match /(.*?)<(.*)>/
      return "#{@makeTypeLink rel_path, res[1]}&lt;#{@makeTypeLink rel_path, res[2]}&gt;"
    else
      return getlink type

  ##
  # @private
  # @param {String} rel_path
  # @param {String} str
  # @return {String}
  makeSeeLink: (rel_path, str) ->
    if @result.ids[str]
      filename = @result.ids[str].filename + '.html'
      html_id = @result.ids[str].html_id
      str = "<a href='#{rel_path}#{filename}##{html_id}'>#{str}</a>"
    return str

  ##
  # Converts link markups to HTML links in the description
  # @private
  # @param {String} rel_path
  # @param {String} str
  # @return {String}
  convertLink: (rel_path, str) ->
    return '' if not str
    str = str.replace /\[\[#([^\[\]]+)\]\]/g, (_, $1) ->
      if @result.ids[$1] and @result.ids[$1] isnt 'DUPLICATED ENTRY'
        filename = @result.ids[$1].filename + '.html'
        html_id = @result.ids[$1].html_id
        return "<a href='#{rel_path}#{filename}##{html_id}'>#{$1}</a>"
      else
        return @makeMissingLink $1
    return str

  ##
  # @private
  # @param {String} source
  # @param {String} target
  # @param {Function} callback
  copyResources: (source, target, callback) ->
    exec = require('child_process').exec
    exec "rm -rf #{target}/* ; mkdir -p #{target} ; cp -a #{source}/* #{target}", ->
      callback()

  ##
  # @private
  renderOne: (options, template, output) ->
    options.result = @result
    options.makeTypeLink = @makeTypeLink.bind(@) if not options.makeTypeLink
    options.makeSeeLink = @makeSeeLink.bind(@)
    options.convertLink = @convertLink.bind(@)
    options.genopts = @genopts
    options.cache = true
    jade.renderFile "#{@templates_dir}/#{template}.jade", options, (error, result) =>
      return console.error error.stack if error
      output_file = "#{@output_dir}/#{output}.html"
      fs.writeFile output_file, result, (error) =>
        return console.error 'failed to create '+output_file if error
        console.log output_file + ' is created' if not @genopts.quite

  ##
  # @private
  renderReadme: ->
    fs.readFile "#{@genopts.readme or @genopts.project_dir}/README.md", 'utf-8', (error, content) =>
      if content
        content = markdown content
      options =
        rel_path: './'
        name: 'README'
        content: content
        type: 'home'
      @renderOne options, 'extra', 'index'

  ##
  # @private
  renderGuides: ->
    return if @result.guides.length is 0
    try fs.mkdirSync "#{@output_dir}/guides"
    @result.guides.forEach (guide) =>
      content = guide.content
      if content
        content = markdown content
      options =
        rel_path: '../'
        name: guide.name
        content: content
        type: 'guides'
      @renderOne options, 'extra', guide.filename

  ##
  # @private
  renderPages: ->
    if @result.pages.length > 0
      options =
        rel_path: './'
        name: 'Pages'
        type: 'pages'
      @renderOne options, 'pages', 'pages'

  ##
  # @private
  renderRESTApis: ->
    if @result.restapis.length > 0
      options =
        rel_path: './'
        name: 'REST APIs'
        type: 'restapis'
      @renderOne options, 'restapis', 'restapis'

  ##
  # @private
  renderClasses: ->
    return if @result.classes.length is 0
    try fs.mkdirSync "#{@output_dir}/classes"
    @result.classes.forEach (klass) =>
      properties = klass.properties.sort (a, b) -> if a.ctx.name < b.ctx.name then -1 else 1
      options =
        rel_path: '../'
        name: klass.ctx.name
        klass: klass
        properties: properties
        type: 'classes'
        makeTypeLink: (path, type) =>
          @makeTypeLink path, type, "(in #{klass.defined_in})"
      @renderOne options, 'class', klass.filename

  ##
  # @private
  renderModules: ->
    return if @result.modules.length is 0
    try fs.mkdirSync "#{@output_dir}/modules"
    @result.modules.forEach (module) =>
      properties = module.properties.sort (a, b) -> if a.ctx.name < b.ctx.name then -1 else 1
      options =
        rel_path: '../'
        name: module.ctx.name
        module_data: module
        properties: properties
        type: 'modules'
      @renderOne options, 'module', module.filename

  ##
  # @private
  renderFeatures: ->
    return if @result.features.length is 0
    try fs.mkdirSync "#{@output_dir}/features"
    @result.features.forEach (feature) =>
      options =
        rel_path: '../'
        name: feature.name
        feature: feature
        type: 'features'
      @renderOne options, 'feature', feature.filename

  ##
  # @private
  renderFiles: ->
    return if @result.files.length is 0
    try fs.mkdirSync "#{@output_dir}/files"
    @result.files.forEach (file) =>
      options =
        rel_path: '../'
        name: file.name
        file: file
        type: 'files'
      @renderOne options, 'file', file.filename

  ##
  # Renders
  render: ->
    @copyResources @resources_dir, @output_dir, =>
      @renderReadme()
      @renderGuides()
      @renderPages()
      @renderRESTApis()
      @renderClasses()
      @renderModules()
      @renderFeatures()
      @renderFiles()

##
# Renders
# @memberOf render
render = (result, genopts) ->
  new Renderer(result, genopts).render()

module.exports = render
