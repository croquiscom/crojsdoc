##
# Renders documentations from result of collector
# @module render
# @see Renderer

fs = require 'fs.extra'
jade = require 'jade'
{resolve, dirname} = require 'path'

##
# Renders documentations from result of collector
class Renderer
  ##
  # Creates a Renderer instance
  constructor: (@result, @options) ->
    theme = 'default'
    @resources_dir = resolve __dirname, '../themes', theme, 'resources'
    @templates_dir = resolve __dirname, '../themes', theme, 'templates'

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
      if @options.types[type]
        link = @options.types[type]
      else if @result.ids[type] and @result.ids[type] isnt 'DUPLICATED ENTRY'
        filename = @result.ids[type].filename + '.html'
        html_id = @result.ids[type].html_id or ''
        link = "#{rel_path}#{filename}##{html_id}"
      else
        return @makeMissingLink type, place
      return "<a href='#{link}'>#{type}</a>"
    if res = type.match(/\[(.*)\]\((.*)\)/)
      @options.types[res[1]] = res[2]
      return "<a href='#{res[2]}'>#{res[1]}</a>"
    if res = type.match /(.*?)\.<(.*)>/
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
      html_id = @result.ids[str].html_id or ''
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
    str = str.replace /\[\[#([^\[\]]+)\]\]/g, (_, $1) =>
      if @result.ids[$1] and @result.ids[$1] isnt 'DUPLICATED ENTRY'
        filename = @result.ids[$1].filename + '.html'
        html_id = @result.ids[$1].html_id or ''
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
    try
      files = fs.readdirSync target
    catch
      files = []
    for file in files
      if file[0] isnt '.'
        fs.rmrfSync resolve target, file
    try fs.mkdirSync target
    fs.copyRecursive source, target, ->
      callback()

  ##
  # @private
  renderOne: (jade_options, template, output) ->
    jade_options.result = @result
    jade_options.makeTypeLink = @makeTypeLink.bind(@) if not jade_options.makeTypeLink
    jade_options.makeSeeLink = @makeSeeLink.bind(@)
    jade_options.convertLink = @convertLink.bind(@)
    jade_options.github = @options.github
    jade_options.cache = true
    jade_options.self = true
    jade.renderFile "#{@templates_dir}/#{template}.jade", jade_options, (error, result) =>
      return console.error error.stack if error
      output_file = "#{@options.output_dir}/#{output}.html"
      fs.writeFile output_file, result, (error) =>
        return console.error 'failed to create '+output_file if error
        console.log output_file + ' is created' if not @options.quite

  ##
  # @private
  renderReadme: ->
    jade_options =
      rel_path: './'
      name: 'README'
      content: @result.readme
      type: 'home'
    @renderOne jade_options, 'extra', 'index'

  ##
  # @private
  renderGuides: ->
    return if @result.guides.length is 0
    try fs.mkdirSync "#{@options.output_dir}/guides"
    @result.guides.forEach (guide) =>
      jade_options =
        rel_path: '../'
        name: guide.name
        content: guide.content
        type: 'guides'
      @renderOne jade_options, 'extra', guide.filename

  ##
  # @private
  renderPages: ->
    if @result.pages.length > 0
      jade_options =
        rel_path: './'
        name: 'Pages'
        type: 'pages'
      @renderOne jade_options, 'pages', 'pages'

  ##
  # @private
  renderRESTApis: ->
    if @result.restapis.length > 0
      jade_options =
        rel_path: './'
        name: 'REST APIs'
        type: 'restapis'
      @renderOne jade_options, 'restapis', 'restapis'

  ##
  # @private
  renderClasses: ->
    return if @result.classes.length is 0
    try fs.mkdirSync "#{@options.output_dir}/classes"
    jade_options =
      rel_path: '../'
      type: 'classes'
    @renderOne jade_options, 'class-toc', 'classes/index'
    @result.classes.forEach (klass) =>
      jade_options =
        rel_path: '../'
        name: klass.ctx.name
        klass: klass
        properties: klass.properties
        type: 'classes'
        makeTypeLink: (path, type) =>
          @makeTypeLink path, type, "(in #{klass.defined_in})"
      @renderOne jade_options, 'class', klass.filename

  ##
  # @private
  renderModules: ->
    return if @result.modules.length is 0
    try fs.mkdirSync "#{@options.output_dir}/modules"
    jade_options =
      rel_path: '../'
      type: 'modules'
    @renderOne jade_options, 'module-toc', 'modules/index'
    @result.modules.forEach (module) =>
      jade_options =
        rel_path: '../'
        name: module.ctx.name
        module_data: module
        properties: module.properties
        type: 'modules'
      @renderOne jade_options, 'module', module.filename

  ##
  # @private
  renderFeatures: ->
    return if @result.features.length is 0
    try fs.mkdirSync "#{@options.output_dir}/features"
    @result.features.forEach (feature) =>
      jade_options =
        rel_path: '../'
        name: feature.name
        feature: feature
        type: 'features'
      @renderOne jade_options, 'feature', feature.filename

  ##
  # @private
  renderFiles: ->
    return if @result.files.length is 0
    try fs.mkdirSync "#{@options.output_dir}/files"
    @result.files.forEach (file) =>
      jade_options =
        rel_path: '../'
        name: file.name
        file: file
        type: 'files'
      @renderOne jade_options, 'file', file.filename

  ##
  # @private
  groupByNamespaces: (items) ->
    if items.length is 0
      return []
    current_group = []
    grouped_items = [current_group]
    current_namespace = items[0].namespace
    items.forEach (item) ->
      if current_namespace isnt item.namespace
        current_group = []
        grouped_items.push current_group
        current_namespace = item.namespace
      current_group.push item
    return grouped_items

  ##
  # Runs
  run: ->
    @result.ns_pages = @groupByNamespaces @result.pages
    @result.ns_restapis = @groupByNamespaces @result.restapis
    @result.ns_classes = @groupByNamespaces @result.classes
    @result.ns_modules = @groupByNamespaces @result.modules
    @result.ns_features = @groupByNamespaces @result.features
    @result.ns_files = @groupByNamespaces @result.files

    @copyResources @resources_dir, @options.output_dir, =>
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
# @param {Result} result
# @param {Options} options
# @memberOf render
render = (result, options) ->
  renderer = new Renderer result, options
  renderer.run()

module.exports = render
