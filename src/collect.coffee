##
# Collects comments from source files
# @module collect
# @see Collector

_ = require 'lodash'
dox = require './dox'
inflect = require 'inflect'
markdown = require 'marked'

is_test_mode = process.env.NODE_ENV is 'test'

##
# Collects comments from source files
class Collector
  ##
  # Create a Collector instance
  constructor: (@contents, @options = {}) ->
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
  # Adds a guide file to the result
  _addGuide: (path, data) ->
    id = path.substr(0, path.length-3)
    name = path.substr(0, path.length-8).replace(/\//g, '.')
    item =
      name: inflect.humanize inflect.underscore name
      filename: 'guides/' + name
      content: markdown data
    @result.guides.push item
    @result.ids[id] = item

  ##
  # Adds a feature file to the result
  _addFeature: (path, data) ->
    name = path.substr 0, path.length-8
    namespace = ''
    name = name.replace /(.*)\//, (_, $1) ->
      namespace = $1 + '/'
      return ''
    feature = ''
    data = data.replace /Feature: (.*)/, (_, $1) ->
      feature = $1
      return ''
    @result.features.push
      name: namespace + name
      namespace: namespace
      filename: 'features/' + namespace.replace(/\//g, '.') + name
      feature: feature
      content: data

  ##
  # Adds a source file to the result
  _addFile: (path, data) ->
    namespace = ''
    name = path.replace /(.*)\//, (_, $1) ->
      namespace = $1 + '/'
      return ''
    @result.files.push
      name: namespace + name
      namespace: namespace
      filename: 'files/' + namespace.replace(/\//g, '.') + name
      content: data

  ##
  # Checks flags of parameter
  #
  # * '[' name ']' : optional
  # * name '=' value : default value
  # * '+' name : addable
  # * '-' name : excludable
  # @param {Object} tag
  # @return {Object} given tag
  _processParamFlags: (tag) ->
    # is optional parameter?
    if tag.name[0] is '[' and tag.name[tag.name.length-1] is ']'
      tag.name = tag.name.substr 1, tag.name.length-2
      if (pos = tag.name.indexOf '=')>=0
        tag.default_value = tag.name.substr pos+1
        tag.name = tag.name.substr 0, pos
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
  # @param {Array<Object>} params
  # @param {String} name
  # @return {Object}
  _findParam: (params, name) ->
    for param in params
      if param.name is name
        return param
      if param.params
        found = @_findParam param.params, name
        return found if found
    return

  ##
  # Makes parameters(or returnprops) nested
  _makeNested: (comment, targetName) ->
    i = comment[targetName].length
    while i-->0
      param = comment[targetName][i]
      if match = param.name.match /\[?([^=]*)\.([^\]]*)\]?/
        parentParam = @_findParam comment[targetName], match[1]
        if parentParam
          comment[targetName].splice i, 1
          parentParam[targetName] = parentParam[targetName] or []
          param.name = match[2]
          parentParam[targetName].unshift param

  ##
  # Apply markdown
  _applyMarkdown: (str) ->
    # we cannot use '###' for header level 3 or above in CoffeeScript, instead web use '##\#', ''##\##', ...
    # recover this for markdown
    str = str.replace /#\\#/g, '##'
    return markdown str

  ##
  # Classifies type and collect id
  _classifyComments: (comments) ->
    current_class = undefined
    current_module = undefined

    comments.forEach (comment) =>
      comment.ctx or comment.ctx = {}
      comment.params = []
      comment.returnprops = []
      comment.throws = []
      comment.resterrors = []
      comment.sees = []
      comment.reverse_sees = []
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
      comment.namespace or= ''

      if comment.ctx.type is 'property' or comment.ctx.type is 'method'
        if comment.ctx.cons?
          comment.isStatic = false
          comment.ctx.class_name = comment.ctx.cons
        else if comment.ctx.receiver?
          comment.isStatic = true
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
          when 'memberof'
            if /(::|#|\.prototype)$/.test tag.parent
              comment.isStatic = false
              comment.ctx.class_name = tag.parent.replace /(::|#|\.prototype)$/, ''
            else
              comment.isStatic = true
              comment.ctx.class_name = tag.parent
          when 'namespace'
            comment.namespace = if tag.string then tag.string else ''
          when 'property'
            comment.ctx.type = tag.type
            comment.ctx.name = tag.name
          when 'method'
            comment.ctx.type = tag.type
            if tag.string
              comment.ctx.name = tag.string
          when 'static'
            comment.isStatic = true
          when 'private'
            comment.isPrivate = true
          when 'abstract'
            comment.isAbstract = true
          when 'async'
            comment.isAsync = true
          when 'promise'
            comment.doesReturnPromise = true
          when 'nodejscallback'
            comment.doesReturnNodejscallback = true
          when 'chainable'
            comment.isChainable = true
          when 'type'
            if not tag.types and tag.typeString
              typeString = tag.typeString
              if not /{.*}/.test typeString
                typeString = '{' + typeString + '}'
              dox.parseTagTypes typeString, tag
          when 'param', 'return', 'returns', 'returnprop', 'throws', 'resterror', 'see'
            , 'extends', 'todo', 'api', 'uses', 'override', 'example'
          else
            console.log "Unknown tag : #{tag.type} in #{comment.full_path}"

      if comment.namespace
        comment.namespace += '.'

      if comment.ctx.class_name
        if comment.ctx.type is 'function'
          comment.ctx.type = 'method'
        else if comment.ctx.type is 'declaration'
          comment.ctx.type = 'property'
        seperator = if comment.isStatic then '.' else '::'
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
        comment.id = id
        if @result.ids.hasOwnProperty id
          @result.ids[id] = 'DUPLICATED ENTRY'
        else
          @result.ids[id] = comment
        if comment.namespace and @result.ids.hasOwnProperty comment.namespace+id
          @result.ids[comment.namespace+id] = 'DUPLICATED ENTRY'
        else
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
  # Returns list of comments of the given file
  # @return {Array<Comment>}
  _getComments: (type, full_path, path, data) ->
    if type is 'coffeescript'
      comments = dox.parseCommentsCoffee data, { raw: true }
      comments.forEach (comment) ->
        comment.language = 'coffeescript'
    else if type is 'javascript'
      comments = dox.parseComments data, { raw: true }
      comments.forEach (comment) ->
        comment.language = 'javascript'
    else if type is 'page'
      namespace = ''
      name = path.substr(0, path.length-3).replace(/[^A-Za-z0-9]*Page$/, '')
      name = name.replace /(.*)\//, (_, $1) ->
        namespace = $1
        return ''
      comments = [ {
        description:
          summary: ''
          body: data
          full: ''
        tags: [
          { type: 'page', string: name }
          { type: 'namespace', string: namespace }
        ]
      } ]

    return if not comments?

    # filter out empty comments
    comments = comments.filter (comment) ->
      return comment.description.full or comment.description.summary or comment.description.body or comment.tags?.length > 0

    comments.forEach (comment) ->
      comment.full_path = full_path
      comment.path = path
      return

    if @options.plugins
      comments.forEach (comment) =>
        @options.plugins.forEach (plugin) ->
          plugin.onComment comment
          return
        return

    @_classifyComments comments

    return comments

  ##
  # Structuralizes comments
  _processComments: (comments) ->
    comments.forEach (comment) =>
      desc = comment.description
      if desc
        desc.full = @_applyMarkdown desc.full
        desc.summary = @_applyMarkdown desc.summary
        desc.body = @_applyMarkdown desc.body

      for tag in comment.tags
        switch tag.type
          when 'param'
            tag = @_processParamFlags tag
            for type, i in tag.types
              tag.types[i] = type
            tag.description = tag.description
            comment.params.push tag
          when 'return', 'returns'
            for type, i in tag.types
              tag.types[i] = type
            tag.description = tag.description
            comment.return = tag
          when 'returnprop'
            tag = dox.parseTag '@param ' + tag.string
            tag = @_processParamFlags tag
            for type, i in tag.types
              tag.types[i] = type
            tag.description = tag.description
            comment.returnprops.push tag
          when 'throws'
            comment.throws.push message: tag.message, description: tag.description
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
        if /^class +\w+ +extends +([\w\.]+)/.exec comment.class_code
          comment.extends.push RegExp.$1
          @result.ids[RegExp.$1]?.subclasses.push comment.ctx.name

      # make parameters nested
      @_makeNested comment, 'params'
      @_makeNested comment, 'returnprops'

      if comment.doesReturnNodejscallback
        callback_params = [ {
            name: 'error'
            types: ['Error']
            description: 'See throws'
          } ]
        if comment.return
          callback_params.push
              name: 'result'
              types: comment.return.types
              description: 'See returns'
        comment.params.push
          name: 'callback'
          types: ['Function']
          optional: comment.doesReturnPromise
          description: 'NodeJS style\'s callback'
          params: callback_params

      if comment.isChainable and not comment.return
        comment.return =
          types: [comment.ctx.class_name]
          description: 'this'

      switch comment.ctx.type
        when 'property', 'method'
          class_name = comment.ctx.class_name
          if class_name and class_comment = @result.classes[class_name]
            if comment.ctx.is_coffeescript_constructor
              # merge to class comment
              class_comment.code = comment.code
              class_comment.codeStart = comment.codeStart
              class_comment.params = comment.params
            else
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
  _refineResult: ->
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
      if a.name < b.name then -1 else 1
    result.features = result.features.sort (a,b) ->
      if a.name < b.name then -1 else 1
    result.files = result.files.sort (a,b) ->
      a_ns = a.namespace
      b_ns = b.namespace
      return -1 if a_ns < b_ns
      return 1 if a_ns > b_ns
      if a.name < b.name then -1 else 1

    result.classes.forEach (klass) ->
      klass.properties.sort (a, b) -> if a.ctx.name < b.ctx.name then -1 else 1
      for property in klass.properties
        property.ctx = _.pick property.ctx, 'type', 'name', 'fullname'

    result.modules = result.classes.filter (klass) -> klass.is_module
    result.classes = result.classes.filter (klass) -> not klass.is_module

  ##
  # Returns the type of a file
  _getType: (path) ->
    if /\.coffee$/.test path
      return 'coffeescript'
    else if /\.js$/.test path
      return 'javascript'
    else if /Page\.md$/.test path
      return 'page'
    else if /Guide\.md$/.test path
      return 'guide'
    else if /\.feature$/.test path
      return 'feature'
    else if path is 'README'
      return 'readme'
    else
      return 'unknown'

  ##
  # Makes reverse see alsos
  _makeReverseSeeAlso: (comments) ->
    for comment in comments
      for see in comment.sees
        other = @result.ids[see]
        if other and other isnt 'DUPLICATED ENTRY'
          me = @result.ids[comment.id]
          if me and me is 'DUPLICATED ENTRY'
            other.reverse_sees?.push comment.namespace+comment.id
          else
            other.reverse_sees?.push comment.id
    return

  ##
  # Runs
  run: ->
    all_comments = []
    file_count_read = 0
    for {full_path, path, data} in @contents
      type = @_getType path
      switch type
        when 'guide'
          @_addGuide path, data
        when 'feature'
          @_addFeature path, data
        when 'coffeescript', 'javascript', 'page'
          comments = @_getComments type, full_path, path, data
          if comments?
            [].push.apply all_comments, comments
        when 'readme'
          @result.readme = markdown data
      if type is 'coffeescript' or type is 'javascript'
        @_addFile path, data
      file_count_read++
      console.log path + ' is processed' if not (@options.quiet or is_test_mode)

    console.log 'Total ' + file_count_read + ' files processed' if not is_test_mode

    @_processComments all_comments

    if @options.reverse_see_also
      @_makeReverseSeeAlso all_comments

    if not @options.files
      @result.files = []
    @_refineResult()

##
# Collects
# @param {Array<Content>} contents
# @param {Options} options
# @return {Result}
# @memberOf collect
collect = (contents, options) ->
  collector = new Collector contents, options
  collector.run()
  return collector.result

module.exports = collect
