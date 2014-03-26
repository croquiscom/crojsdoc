##
# @module collect

dox = require './dox'
fs = require 'fs'
glob = require 'glob'
markdown = require 'marked'
walkdir = require 'walkdir'
{basename,dirname,resolve} = require 'path'

##
# Collector
class Collector
  constructor: (@paths, @options) ->
    @result =
      project_title: @options.title or 'croquis-jsdoc'
      ids: {}
      classes: {}
      guides: []
      pages: {}
      restapis: {}
      features: []
      files: []

  ##
  # Returns list of comments of the given file
  # @private
  # @param {String} file
  # @return {Array<Comment>}
  getComments: (file, path) ->
    return if fs.statSync(file).isDirectory()
    content = fs.readFileSync(file, 'utf-8').trim()
    return if not content

    file = file.substr(path.length+1)

    if /\.coffee$/.test file
      comments = dox.parseCommentsCoffee content, { raw: true }
      add_to_file = true
    else if /\.js$/.test file
      comments = dox.parseComments content, { raw: true }
      add_to_file = true
    else if /Page\.md$/.test file
      namespace = ''
      file = file.substr(0, file.length-3).replace(/[^A-Za-z0-9]*Page$/, '')
      file = file.replace /(.*)\//, (_, $1) ->
        namespace = $1
        return ''
      comments = [ {
        description:
          summary: ''
          body: content
          full: ''
        tags: [
          { type: 'page', string: file }
          { type: 'namespace', string: namespace }
        ]
      } ]
    else if /Guide\.md$/.test file
      file = file.substr(0, file.length-8).replace(/\//g, '.')
      @result.guides.push
        name: file
        filename: 'guides/' + file
        content: content
    else if /\.feature$/.test file
      file = file.substr 0, file.length-8
      namespace = ''
      file = file.replace /(.*)\//, (_, $1) ->
        namespace = $1 + '/'
        return ''
      feature = ''
      content = content.replace /Feature: (.*)/, (_, $1) ->
        feature = $1
        return ''
      @result.features.push
        name: namespace + file
        namespace: namespace
        filename: 'features/' + namespace.replace(/\//g, '.') + file
        feature: feature
        content: content

    if add_to_file
      namespace = ''
      file = file.replace /(.*)\//, (_, $1) ->
        namespace = $1 + '/'
        return ''
      @result.files.push
        name: namespace + file
        namespace: namespace
        filename: 'files/' + namespace.replace(/\//g, '.') + file
        content: content

    # filter out empty comments
    return comments?.filter (comment) ->
      return comment.description.full or comment.description.summary or comment.description.body or comment.tags?.length > 0

  ##
  # Checks flags of parameter
  #
  # * '[' name ']' : optional
  # * name '=' value : default value
  # * '+' name : addable
  # * '-' name : excludable
  # @private
  # @param {Object} tag
  # @return {Object} given tag
  processParamFlags: (tag) ->
    # is optional parameter?
    if /\[([^\[\]]+)\]/.exec tag.name
      tag.name = RegExp.$1
      tag.optional = true
    if tag.name.substr(0, 1) is '+'
      tag.name = tag.name.substr(1)
      tag.addable = true
    if tag.name.substr(0, 1) is '-'
      tag.name = tag.name.substr(1)
      tag.excludable = true
    return tag

  ##
  # Finds a parameter in the list
  # @private
  # @param {Array<Object>} params
  # @param {String} name
  # @return {Object}
  findParam: (params, name) ->
    for param in params
      if param.name is name
        return param
      if param.params
        found = @findParam param.params, name
        return found if found
    return

  ##
  # Makes parameters(or returnprops) nested
  # @private
  makeNested: (comment, targetName) ->
    i = comment[targetName].length
    while i-->0
      param = comment[targetName][i]
      if match = param.name.match /\[?([^=]*)\.([^\]]*)\]?/
        parentParam = @findParam comment[targetName], match[1]
        if parentParam
          comment[targetName].splice i, 1
          parentParam[targetName] = parentParam[targetName] or []
          param.name = match[2]
          parentParam[targetName].unshift param

  ##
  # Apply markdown
  # @private
  applyMarkdown: (str) ->
    # we cannot use '###' for header level 3 or above in CoffeeScript, instead web use '##\#', ''##\##', ...
    # recover this for markdown
    str = str.replace /#\\#/g, '##'
    return markdown str

  ##
  # Classifies type and collect id
  # @private
  classifyComments: (file, comments) ->
    current_class = undefined
    current_module = undefined

    comments.forEach (comment) =>
      comment.defined_in = file
      comment.ctx or comment.ctx = {}
      comment.params = []
      comment.returnprops = []
      comment.throws = []
      comment.resterrors = []
      comment.sees = []
      comment.todos = []
      comment.extends = []
      comment.subclasses = []
      comment.uses = []
      comment.usedbys = []
      comment.properties = []
      comment.examples = []

      if comment.ctx.type is 'property' or comment.ctx.type is 'method'
        id = comment.ctx.string.replace('()', '')
      else
        id = comment.ctx.name
      comment.ctx.fullname = id
      comment.namespace = ''

      if comment.ctx.type is 'property' or comment.ctx.type is 'method'
        if comment.ctx.cons?
          comment.static = false
          comment.ctx.class_name = comment.ctx.cons
        else if comment.ctx.receiver?
          comment.static = true
          comment.ctx.class_name = comment.ctx.receiver

      last = 0
      for tag, i in comment.tags
        if tag.type is ''
          comment.tags[last].string += "\n#{tag.string}"
          continue
        last = i
        switch tag.type
          when 'page', 'restapi', 'class'
            comment.ctx.type = tag.type
            if tag.string
              comment.ctx.name = tag.string
              comment.ctx.fullname = id = comment.ctx.name
          when 'module'
            comment.ctx.type = 'class'
            comment.is_module = true
            if tag.string
              comment.ctx.name = tag.string
              comment.ctx.fullname = id = comment.ctx.name
            comment.code = null
          when 'memberOf'
            if /(::|#|prototype)$/.test tag.parent
              comment.static = false
              comment.ctx.class_name = tag.parent.replace /(::|#|prototype)$/, ''
            else
              comment.static = true
              comment.ctx.class_name = tag.parent
          when 'namespace'
            comment.namespace = if tag.string then tag.string + '.' else ''
          when 'property', 'method'
            comment.ctx.type = tag.type
            comment.ctx.name = tag.string
          when 'static'
            comment.static = true
          when 'private'
            comment.isPrivate = true
          when 'abstract'
            comment.abstract = true
          when 'async'
            comment.async = true
          when 'param', 'return', 'returnprop', 'throws', 'resterror', 'see'
            , 'extends', 'todo', 'type', 'api', 'uses', 'override'
          else
            console.log "Unknown tag : #{tag.type} in #{file}"

      if comment.ctx.class_name
        if comment.ctx.type is 'function'
          comment.ctx.type = 'method'
        else if comment.ctx.type is 'declaration'
          comment.ctx.type = 'property'
        seperator = if comment.static then '.' else '::'
        id = comment.ctx.class_name + seperator + comment.ctx.name
        comment.ctx.fullname = comment.ctx.class_name.replace(/.*[\./](\w+)/, '$1') + seperator + comment.ctx.name

      if comment.ctx.type is 'class'
        current_class = comment
        if comment.is_module
          current_module = comment

      if (comment.ctx.type is 'property' or comment.ctx.type is 'method') and not comment.namespace
        if current_class
          comment.namespace = current_class.namespace
        if current_module and not comment.ctx.class_name
          comment.ctx.class_name = current_module.ctx.name

      if id
        if @result.ids.hasOwnProperty id
          @result.ids[id] = 'DUPLICATED ENTRY'
        else
          @result.ids[id] = comment
          @result.ids[comment.namespace+id] = comment
        comment.html_id = (comment.namespace+id).replace(/[^A-Za-z0-9_]/g, '_')

      switch comment.ctx.type
        when 'class'
          comment.ctx.name = comment.namespace + comment.ctx.name
          comment.ctx.fullname = comment.namespace + comment.ctx.fullname
          @result.classes[comment.ctx.name] = comment
          if comment.is_module
            comment.filename = 'modules/' + comment.ctx.name.replace(/\//g, '.')
          else
            comment.filename = 'classes/' + comment.ctx.name.replace(/\//g, '.')
        when 'property', 'method'
          comment.ctx.class_name = comment.namespace + comment.ctx.class_name
          comment.filename = 'classes/' + comment.ctx.class_name.replace(/\//g, '.')
        when 'page'
          comment.filename = 'pages'
        when 'restapi'
          comment.filename = 'restapis'

  ##
  # Structuralizes comments
  # @private
  processComments: (comments) ->
    comments.forEach (comment) =>
      desc = comment.description
      if desc
        desc.full = @applyMarkdown desc.full
        desc.summary = @applyMarkdown desc.summary
        desc.body = @applyMarkdown desc.body

      for tag in comment.tags
        switch tag.type
          when 'param'
            tag = @processParamFlags tag
            for type, i in tag.types
              tag.types[i] = type
            tag.description = tag.description
            comment.params.push tag
          when 'return'
            for type, i in tag.types
              tag.types[i] = type
            tag.description = tag.description
            comment.return = tag
          when 'returnprop'
            tag = dox.parseTag '@param ' + tag.string
            tag = @processParamFlags tag
            for type, i in tag.types
              tag.types[i] = type
            tag.description = tag.description
            comment.returnprops.push tag
          when 'throws'
            if /{([^}]+)}\s*(.*)/.exec tag.string
              comment.throws.push message: RegExp.$1, description: RegExp.$2
            else
              comment.throws.push message: tag.string, description: ''
          when 'resterror'
            if /{(\d+)\/([A-Za-z0-9_ ]+)}\s*(.*)/.exec tag.string
              comment.resterrors.push code: RegExp.$1, message: RegExp.$2, description: RegExp.$3
          when 'see'
            str = tag.local or tag.url
            comment.sees.push str
          when 'todo'
            comment.todos.push tag.string
          when 'extends'
            comment.extends.push tag.string
            @result.ids[tag.string]?.subclasses.push comment.ctx.name
          when 'uses'
            comment.uses.push tag.string
            @result.ids[tag.string]?.usedbys.push comment.ctx.name
          when 'type'
            for type, i in tag.types
              tag.types[i] = type
            comment.types = tag.types
          when 'example'
            comment.examples.push tag
          when 'override'
            if @result.ids[tag.string] and @result.ids[tag.string] isnt 'DUPLICATED ENTRY'
              comment.override = @result.ids[tag.string]
            comment.override_link = tag.string

      if comment.ctx.type is 'class'
        if /^class +\w+ +extends +([\w\.]+)/.exec comment.code
          comment.extends.push RegExp.$1
          @result.ids[RegExp.$1]?.subclasses.push comment.ctx.name

      # make parameters nested
      @makeNested comment, 'params'
      @makeNested comment, 'returnprops'

      switch comment.ctx.type
        when 'property', 'method'
          class_name = comment.ctx.class_name
          if class_name and class_comment = @result.classes[class_name]
            class_comment.properties.push comment
            if class_comment.is_module
              comment.filename = comment.filename.replace('classes/', 'modules/')
        when 'page'
          @result.pages[comment.ctx.name] = comment
        when 'restapi'
          @result.restapis[comment.ctx.name] = comment

  ##
  # Refines result.
  #
  # - convert hash to sorted array
  # - classes -> classes & modules
  refineResult: ->
    result = @result
    result.classes = Object.keys(result.classes).sort( (a,b) ->
      a_ns = result.classes[a].namespace
      b_ns = result.classes[b].namespace
      return -1 if a_ns < b_ns
      return 1 if a_ns > b_ns
      if a<b then -1 else 1
    ).map (name) -> result.classes[name]
    result.pages = Object.keys(result.pages).sort( (a,b) ->
      a_ns = result.pages[a].namespace
      b_ns = result.pages[b].namespace
      return -1 if a_ns < b_ns
      return 1 if a_ns > b_ns
      if a<b then -1 else 1
    ).map (name) -> result.pages[name]
    result.restapis = Object.keys(result.restapis).sort( (a,b) ->
      a_ns = result.restapis[a].namespace
      b_ns = result.restapis[b].namespace
      return -1 if a_ns < b_ns
      return 1 if a_ns > b_ns
      a = a.replace /([A-Z]+) \/(.*)/, '-$2 $1'
      b = b.replace /([A-Z]+) \/(.*)/, '-$2 $1'
      if a<b then -1 else 1
    ).map (name) -> result.restapis[name]
    result.guides = result.guides.sort (a,b) ->
      if a.name<b.name then -1 else 1
    result.features = result.features.sort (a,b) ->
      if a.name<b.name then -1 else 1
    result.files = result.files.sort (a,b) ->
      a_ns = a.namespace
      b_ns = b.namespace
      return -1 if a_ns < b_ns
      return 1 if a_ns > b_ns
      if a.name<b.name then -1 else 1

    result.modules = result.classes.filter (klass) -> klass.is_module
    result.classes = result.classes.filter (klass) -> not klass.is_module

  ##
  # Runs
  run: ->
    file_count_read = 0

    all_comments = []
    @paths.forEach (path) =>
      base_path = path = resolve @options.project_dir, path
      base_path = dirname base_path while /[*?]/.test basename(base_path)
      glob.sync(path).forEach (path) =>
        if fs.statSync(path).isDirectory()
          list = walkdir.sync path
        else
          list = [path]
        list.forEach (file) =>
          comments = @getComments file, base_path
          return if not comments?

          file_count_read++
          console.log file + ' is processed' if not @options.quite

          file = file.replace new RegExp("^" + @options.project_dir), ''
          @classifyComments file, comments
          all_comments.push.apply all_comments, comments

    console.log 'Total ' + file_count_read + ' files processed'

    @processComments all_comments

    if not @options.files
      @result.files = []
    @refineResult()

##
# Collects
# @memberOf collect
collect = (paths, options) ->
  collector = new Collector paths, options
  collector.run()
  return collector.result

module.exports = collect
