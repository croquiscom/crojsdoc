dox = require './dox'
fs = require 'fs'
jade = require 'jade'
walkdir = require 'walkdir'
markdown = require 'marked'

###
# Links for pre-known types
###
types =
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

makeMissingLink = (type) ->
  if result.ids[type]
    console.log "'#{type}' link is ambiguous"
  else
    console.log "'#{type}' link does not exist"
  return "<span class='missing-link'>#{type}</span>"

###
# Makes links for given type
#
# "String" -> "<a href='reference url for String'>String</a>"
# "Array<Model>" -> "<a href='reference url for Array'>Array</a>&lt;<a href='internal url for Model'>Model</a>&gt;"
# @param {String} type
# @return {String}
###
makeTypeLink = (type) ->
  return type if not type
  getlink = (type) ->
    if types[type]
      link = types[type]
    else if result.ids[type] and result.ids[type] isnt 'DUPLICATED ENTRY'
      filename = result.ids[type].filename + '.html'
      html_id = result.ids[type].html_id
      link = "#{filename}##{html_id}"
    else
      return makeMissingLink type
    return "<a href='#{link}'>#{type}</a>"
  if res = type.match /(.*)<(.*)>/
    return "#{getlink res[1]}&lt;#{getlink res[2]}&gt;"
  else
    return getlink type

###
# Returns list of comments of the given file
# @param {String} file
# @return {Array<Object>}
# @returnprop {Object} description
# @returnprop {String} description.summary
# @returnprop {String} description.body
# @returnprop {String} description.full
# @returnprop {Array<Object>} tags
# @returnprop {String} tags.type
# @returnprop {Array<String>} [tags.types]
# @returnprop {String} [tags.name]
# @returnprop {String} [tags.description]
# @returnprop {String} [tags.string]
# @returnprop {String} code
# @returnprop {Object} ctx
# @returnprop {String} ctx.type
# @returnprop {String} ctx.name
# @returnprop {String} ctx.string
# @returnprop {String} ctx.constructor
# @returnprop {String} ctx.receiver
###
getComments = (file, path) ->
  return if (fs.statSync file).isDirectory()
  content = fs.readFileSync(file, 'utf-8').trim()
  return if not content

  file = file.substr(path.length+1)

  if /\.coffee$/.test file
    comments = dox.parseCommentsCoffee content, { raw: true }
  else if /\.js$/.test file
    comments = dox.parseComments content, { raw: true }
  else if /Page\.md$/.test file
    namespace = ''
    file = file.substr 0, file.length-3
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

  # filter out empty comments
  return comments?.filter (comment) ->
    return comment.description.full or comment.description.summary or comment.description.body

###
# Parsed result
###
result =
  project_title: ''
  ids: {}
  classes: {}
  pages: {}
  restapis: {}

###
# Checks flags of parameter
#
# * is optional?
# * default value
# @param {Object} tag
# @return {Object} given tag
###
processParamFlags = (tag) ->
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

###
# Finds a parameter in the list
# @param {Array<Object>} params
# @param {String} name
# @return {Object}
###
findParam = (params, name) ->
  for param in params
    if param.name is name
      return param
    if param.params
      found = findParam param.params, name
      return found if found
  return

###
# Makes parameters(or returnprops) nested
###
makeNested = (comment, targetName) ->
  i = comment[targetName].length
  while i-->0
    param = comment[targetName][i]
    if match = param.name.match /\[?(.*)\.([^\]]*)\]?/
      parentParam = findParam comment[targetName], match[1]
      if parentParam
        comment[targetName].splice i, 1
        parentParam[targetName] = parentParam[targetName] or []
        param.name = match[2]
        parentParam[targetName].unshift param

###
# Converts link markups to HTML links in the description
###
convertLink = (str) ->
  str = str.replace /\[\[#([^\[\]]+)\]\]/g, (_, $1) ->
    if result.ids[$1] and result.ids[$1] isnt 'DUPLICATED ENTRY'
      filename = result.ids[$1].filename + '.html'
      html_id = result.ids[$1].html_id
      return "<a href='#{filename}##{html_id}'>#{$1}</a>"
    else
      return makeMissingLink $1
  return str

###
# Apply markdown
###
applyMarkdown = (str) ->
  # we cannot use '###' for header level 3 or above in CoffeeScript, instead web use '##\#', ''##\##', ...
  # recover this for markdown
  str = str.replace /#\\#/g, '##'
  return markdown str

###
# Classifies type and collect id
###
classifyComments = (file, comments) ->
  comments.forEach (comment) ->
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
    comment.properties = []

    if comment.ctx.type is 'property' or comment.ctx.type is 'method'
      id = comment.ctx.string.replace('()', '')
    else
      id = comment.ctx.name
    comment.ctx.fullname = id
    comment.namespace = ''

    if comment.ctx.type is 'property' or comment.ctx.type is 'method'
      if comment.ctx.hasOwnProperty 'constructor'
        comment.static = false
        comment.ctx.class_name = comment.ctx.constructor
      else if comment.ctx.receiver?
        comment.static = true
        comment.ctx.class_name = comment.ctx.receiver

    for tag in comment.tags
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
        when 'property'
          comment.ctx.type = 'property'
          comment.ctx.name = tag.string
        when 'static'
          comment.static = true
        when 'param', 'return', 'returnprop', 'throws', 'resterror', 'see', 'extends', 'todo', 'type'
        else
          console.log "Unknown tag : #{tag.type} in #{file}"

    if comment.ctx.class_name
      seperator = if comment.static then '.' else '::'
      id = comment.ctx.class_name + seperator + comment.ctx.name
      comment.ctx.fullname = comment.ctx.class_name.replace(/.*[\./](\w+)/, '$1') + seperator + comment.ctx.name

    if id
      if result.ids.hasOwnProperty id
        result.ids[id] = 'DUPLICATED ENTRY'
      else
        result.ids[id] = comment
        result.ids[comment.namespace+id] = comment
      comment.html_id = (comment.namespace+id).replace(/[^A-Za-z0-9_]/g, '_')

    switch comment.ctx.type
      when 'class'
        comment.ctx.name = comment.namespace + comment.ctx.name
        comment.ctx.fullname = comment.namespace + comment.ctx.fullname
        result.classes[comment.ctx.name] = comment
        comment.filename = comment.ctx.name.replace(/\//g, '.')
      when 'property', 'method'
        comment.ctx.class_name = comment.namespace + comment.ctx.class_name
        comment.filename = comment.ctx.class_name.replace(/\//g, '.')
      when 'page'
        comment.filename = 'pages'
      when 'restapi'
        comment.filename = 'restapis'

###
# Structuralizes comments
###
processComments = (comments) ->
  comments.forEach (comment) ->
    desc = comment.description
    if desc
      desc.full = convertLink applyMarkdown desc.full
      desc.summary = convertLink applyMarkdown desc.summary
      desc.body = convertLink applyMarkdown desc.body

    for tag in comment.tags
      switch tag.type
        when 'param'
          tag = processParamFlags tag
          for type, i in tag.types
            tag.types[i] = makeTypeLink type
          tag.description = convertLink tag.description
          comment.params.push tag
        when 'return'
          for type, i in tag.types
            tag.types[i] = makeTypeLink type
          tag.description = convertLink tag.description
          comment.return = tag
        when 'returnprop'
          tag = dox.parseTag '@param ' + tag.string
          tag = processParamFlags tag
          for type, i in tag.types
            tag.types[i] = makeTypeLink type
          tag.description = convertLink tag.description
          comment.returnprops.push tag
        when 'throws'
          if /{([^}]+)}\s*(.*)/.exec tag.string
            comment.throws.push message: RegExp.$1, description: convertLink RegExp.$2
          else
            comment.throws.push message: tag.string, description: ''
        when 'resterror'
          if /{(\d+)\/([A-Za-z0-9_ ]+)}\s*(.*)/.exec tag.string
            comment.resterrors.push code: RegExp.$1, message: RegExp.$2, description: convertLink RegExp.$3
        when 'see'
          str = tag.local or tag.url
          if result.ids[str]
            filename = result.ids[str].filename + '.html'
            html_id = result.ids[str].html_id
            str = "<a href='#{filename}##{html_id}'>#{str}</a>"
          comment.sees.push str
        when 'todo'
          comment.todos.push tag.string
        when 'extends'
          comment.extends.push makeTypeLink tag.string
          result.classes[tag.string]?.subclasses.push makeTypeLink comment.ctx.name
        when 'type'
          for type, i in tag.types
            tag.types[i] = makeTypeLink type
          comment.types = tag.types

    if comment.ctx.type is 'class'
      if /^class +\w+ +extends +(\w+)/.exec comment.code
        comment.extends.push makeTypeLink RegExp.$1
        result.classes[RegExp.$1]?.subclasses.push makeTypeLink comment.ctx.name

    # make parameters nested
    makeNested comment, 'params'
    makeNested comment, 'returnprops'

    switch comment.ctx.type
      when 'property', 'method'
        class_name = comment.ctx.class_name
        if class_name
          result.classes[class_name]?.properties.push comment
      when 'page'
        result.pages[comment.ctx.name] = comment
      when 'restapi'
        result.restapis[comment.ctx.name] = comment

copyResources = (source, target) ->
  exec = require('child_process').exec
  exec "mkdir #{target} ; cp -a #{source}/bootstrap #{source}/google-code-prettify #{source}/tocify #{source}/style.css #{target}"

generate = (paths, genopts) ->
  result.project_title = genopts?.title or 'croquis-jsdoc'

  if genopts?['external-types']
    try
      content = fs.readFileSync(genopts['external-types'], 'utf-8').trim()
      try
        ext_types = JSON.parse content
        for type, url of ext_types
          types[type] = url
      catch e
        console.log "external-types: Invalid JSON file"
    catch e
      console.log "external-types: Cannot open #{genopts['external-types']}"

  project_dir = process.cwd()
  doc_dir = project_dir + '/doc'
  template_dir = __dirname + '/templates'

  all_comments = []
  paths.forEach (path) ->
    path = "#{project_dir}/#{path}"
    walkdir.sync(path).forEach (file) ->
      comments = getComments file, path
      return if not comments?
      file = file.replace new RegExp("^" + project_dir), ''
      classifyComments file, comments
      all_comments.push.apply all_comments, comments

  processComments all_comments

  copyResources __dirname, doc_dir

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

  result.modules = result.classes.filter (klass) -> klass.is_module
  result.classes = result.classes.filter (klass) -> not klass.is_module

  fs.readFile "#{project_dir}/README.md", 'utf-8', (error, content) ->
    if content
      content = convertLink applyMarkdown content
    options =
      name: 'README'
      content: content
      type: 'home'
      result: result
    jade.renderFile "#{template_dir}/extra.jade", options, (error, result) ->
      return console.error error.stack if error
      file = "#{doc_dir}/index.html"
      fs.writeFile file, result, (error) ->
        return console.error 'failed to create '+file if error
        console.log file + ' is created' if not genopts.quite

  if result.pages.length > 0
    options =
      name: 'Pages'
      type: 'pages'
      result: result
    jade.renderFile "#{template_dir}/pages.jade", options, (error, result) ->
      return console.error error.stack if error
      file = "#{doc_dir}/pages.html"
      fs.writeFile file, result, (error) ->
        return console.error 'failed to create '+file if error
        console.log file + ' is created' if not genopts.quite

  if result.restapis.length > 0
    options =
      name: 'REST APIs'
      type: 'restapis'
      result: result
    jade.renderFile "#{template_dir}/restapis.jade", options, (error, result) ->
      return console.error error.stack if error
      file = "#{doc_dir}/restapis.html"
      fs.writeFile file, result, (error) ->
        return console.error 'failed to create '+file if error
        console.log file + ' is created' if not genopts.quite

  result.classes.forEach (klass) ->
    properties = klass.properties.sort (a, b) -> if a.ctx.name < b.ctx.name then -1 else 1
    options =
      name: klass.ctx.name
      klass: klass
      properties: properties
      type: 'classes'
      result: result
    jade.renderFile "#{template_dir}/class.jade", options, (error, result) ->
      return console.error error.stack if error
      file = "#{doc_dir}/#{klass.filename}.html"
      fs.writeFile file, result, (error) ->
        return console.error 'failed to create '+file if error
        console.log file + ' is created' if not genopts.quite

  result.modules.forEach (module) ->
    properties = module.properties.sort (a, b) -> if a.ctx.name < b.ctx.name then -1 else 1
    options =
      name: module.ctx.name
      module: module
      properties: properties
      type: 'modules'
      result: result
    jade.renderFile "#{template_dir}/module.jade", options, (error, result) ->
      return console.error error.stack if error
      file = "#{doc_dir}/#{module.filename}.html"
      fs.writeFile file, result, (error) ->
        return console.error 'failed to create '+file if error
        console.log file + ' is created' if not genopts.quite

module.exports = generate
