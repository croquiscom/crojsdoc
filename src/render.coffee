##
# Renders documentations from result of collector
# @module render
# @see Renderer

fs = require 'fs.extra'
pug = require 'pug'
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
  # @param {String} type
  # @return {String}
  _makeMissingLink: (type, place = '') ->
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
  # @param {String} rel_path
  # @param {String} type
  # @return {String}
  _makeTypeLink: (rel_path, type, place = '') ->
    return type if not type
    getlink = (type) =>
      if @options.types[type]
        link = @options.types[type]
      else if @result.ids[type] and @result.ids[type] isnt 'DUPLICATED ENTRY'
        filename = @result.ids[type].filename + '.html'
        html_id = @result.ids[type].html_id or ''
        link = "#{rel_path}#{filename}##{html_id}"
      else
        return @_makeMissingLink type, place
      return "<a href='#{link}'>#{type}</a>"
    if res = type.match(/\[(.*)\]\((.*)\)/)
      @options.types[res[1]] = res[2]
      return "<a href='#{res[2]}'>#{res[1]}</a>"
    if res = type.match /(.*?)<(.*)>/
      return "#{@_makeTypeLink rel_path, res[1]}&lt;#{@_makeTypeLink rel_path, res[2]}&gt;"
    else
      return getlink type

  ##
  # @param {String} rel_path
  # @param {String} str
  # @return {String}
  _makeSeeLink: (rel_path, str) ->
    if @result.ids[str]
      filename = @result.ids[str].filename + '.html'
      html_id = @result.ids[str].html_id or ''
      str = "<a href='#{rel_path}#{filename}##{html_id}'>#{str}</a>"
    return str

  ##
  # Converts link markups to HTML links in the description
  # @param {String} rel_path
  # @param {String} str
  # @return {String}
  _convertLink: (rel_path, str) ->
    return '' if not str
    str = str.replace /\[\[#([^\[\]]+)\]\]/g, (_, $1) =>
      if @result.ids[$1] and @result.ids[$1] isnt 'DUPLICATED ENTRY'
        filename = @result.ids[$1].filename + '.html'
        html_id = @result.ids[$1].html_id or ''
        return "<a href='#{rel_path}#{filename}##{html_id}'>#{$1}</a>"
      else
        return @_makeMissingLink $1
    return str

  ##
  # @param {String} source
  # @param {String} target
  # @param {Function} callback
  _copyResources: (source, target, callback) ->
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
  # Renders one template
  _renderOne: (pug_options, template, output) ->
    pug_options.result = @result
    pug_options.makeTypeLink = @_makeTypeLink.bind(@) if not pug_options.makeTypeLink
    pug_options.makeSeeLink = @_makeSeeLink.bind(@)
    pug_options.convertLink = @_convertLink.bind(@)
    pug_options.github = @options.github
    pug_options.cache = true
    pug_options.self = true
    pug.renderFile "#{@templates_dir}/#{template}.pug", pug_options, (error, result) =>
      return console.error error.stack if error
      output_file = "#{@options.output_dir}/#{output}.html"
      fs.writeFile output_file, result, (error) =>
        return console.error 'failed to create '+output_file if error
        console.log output_file + ' is created' if not @options.quiet

  ##
  # Renders the README
  _renderReadme: ->
    pug_options =
      rel_path: './'
      name: 'README'
      content: @result.readme
      type: 'home'
    @_renderOne pug_options, 'extra', 'index'

  ##
  # Renders guides
  _renderGuides: ->
    return if @result.guides.length is 0
    try fs.mkdirSync "#{@options.output_dir}/guides"
    @result.guides.forEach (guide) =>
      pug_options =
        rel_path: '../'
        name: guide.name
        content: guide.content
        type: 'guides'
      @_renderOne pug_options, 'extra', guide.filename

  ##
  # Renders pages
  _renderPages: ->
    if @result.pages.length > 0
      pug_options =
        rel_path: './'
        name: 'Pages'
        type: 'pages'
      @_renderOne pug_options, 'pages', 'pages'

  ##
  # Renders REST apis
  _renderRESTApis: ->
    if @result.restapis.length > 0
      pug_options =
        rel_path: './'
        name: 'REST APIs'
        type: 'restapis'
      @_renderOne pug_options, 'restapis', 'restapis'

  ##
  # Renders classes
  _renderClasses: ->
    return if @result.classes.length is 0
    try fs.mkdirSync "#{@options.output_dir}/classes"
    pug_options =
      rel_path: '../'
      type: 'classes'
    @_renderOne pug_options, 'class-toc', 'classes/index'
    @result.classes.forEach (klass) =>
      pug_options =
        rel_path: '../'
        name: klass.ctx.name
        klass: klass
        properties: klass.properties
        type: 'classes'
        _makeTypeLink: (path, type) =>
          @_makeTypeLink path, type, "(in #{klass.full_path})"
      @_renderOne pug_options, 'class', klass.filename

  ##
  # Renders modules
  _renderModules: ->
    return if @result.modules.length is 0
    try fs.mkdirSync "#{@options.output_dir}/modules"
    pug_options =
      rel_path: '../'
      type: 'modules'
    @_renderOne pug_options, 'module-toc', 'modules/index'
    @result.modules.forEach (module) =>
      pug_options =
        rel_path: '../'
        name: module.ctx.name
        module_data: module
        properties: module.properties
        type: 'modules'
      @_renderOne pug_options, 'module', module.filename

  ##
  # Renders features
  _renderFeatures: ->
    return if @result.features.length is 0
    try fs.mkdirSync "#{@options.output_dir}/features"
    @result.features.forEach (feature) =>
      pug_options =
        rel_path: '../'
        name: feature.name
        feature: feature
        type: 'features'
      @_renderOne pug_options, 'feature', feature.filename

  ##
  # Renders files
  _renderFiles: ->
    return if @result.files.length is 0
    try fs.mkdirSync "#{@options.output_dir}/files"
    @result.files.forEach (file) =>
      pug_options =
        rel_path: '../'
        name: file.name
        file: file
        type: 'files'
      @_renderOne pug_options, 'file', file.filename

  ##
  # Groups items by namespaces
  _groupByNamespaces: (items) ->
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
    @result.ns_pages = @_groupByNamespaces @result.pages
    @result.ns_restapis = @_groupByNamespaces @result.restapis
    @result.ns_classes = @_groupByNamespaces @result.classes
    @result.ns_modules = @_groupByNamespaces @result.modules
    @result.ns_features = @_groupByNamespaces @result.features
    @result.ns_files = @_groupByNamespaces @result.files

    @_copyResources @resources_dir, @options.output_dir, =>
      @_renderReadme()
      @_renderGuides()
      @_renderPages()
      @_renderRESTApis()
      @_renderClasses()
      @_renderModules()
      @_renderFeatures()
      @_renderFiles()

##
# Renders
# @param {Result} result
# @param {Options} options
# @memberOf render
render = (result, options) ->
  renderer = new Renderer result, options
  renderer.run()

module.exports = render
