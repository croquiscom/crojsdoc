dox = require 'dox'
fs = require 'fs'
jade = require 'jade'
walkdir = require 'walkdir'

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

makeTypeLink = (type) ->
  getlink = (type) ->
    if types[type]
      link = types[type]
    else if result.ids[type]
      filename = result.ids[type].filename + '.html'
      html_id = result.ids[type].html_id
      link = "#{filename}##{html_id}"
    else
      link = '#'
    return "<a href='#{link}'>#{type}</a>"
  if res = type.match /(.*)<(.*)>/
    return "#{getlink res[1]}&lt;#{getlink res[2]}&gt;"
  else
    return getlink type

getComments = (file) ->
  return if (fs.statSync file).isDirectory()
  return if not /\.coffee$/.test(file) and not /\.js$/.test(file)

  content = fs.readFileSync(file, 'utf-8').trim()
  return if not content

  if /\.coffee$/.test file
    dox.parseCommentsCoffee content
  else
    dox.parseComments content

result =
  ids: {}
  classes: {}
  pages: {}
  restapis: {}

processParamFlags = (tag) ->
  # is optional parameter?
  if /\[([^\[\]]+)\]/g.test tag.name
    tag.name = tag.name.replace /\[([^\[\]]+)\]/g, (_, $1) ->
      return $1
    tag.optional = true
  return tag

findParam = (params, name) ->
  for param in params
    if param.name is name
      return param
    if param.params
      found = findParam param.params, name
      return found if found
  return

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

convertLink = (str) ->
  str = str.replace /\[\[#([^\[\]]+)\]\]/g, (_, $1) ->
    if result.ids[$1]
      filename = result.ids[$1].filename + '.html'
      html_id = result.ids[$1].html_id
      return "<a href='#{filename}##{html_id}'>#{$1}</a>"
    else
      return $1
  return str

convertLinkParam = (param) ->
  if param.params
    for subparam, i in param.params
      convertLinkParam subparam
  for type, i in param.types
    funcparams = []
    if type is 'Function' and param.params
      funcparams = param.params.map (p) -> p.name
    type = makeTypeLink type
    if funcparams.length > 0
      type += '(' + funcparams.join(', ') + ')'
    param.types[i] = type

convertLinkComment = (comment) ->
  desc = comment.description
  if desc
    desc.full = convertLink desc.full
    desc.summary = convertLink desc.summary
    desc.body = convertLink desc.body

  for property in comment.properties
    convertLinkComment property

  for param, i in comment.params
    convertLinkParam param

  ret = comment.return
  if ret?.types
    for type, i in ret.types
      ret.types[i] = makeTypeLink type

processComments = (file, comments) ->
  comments.forEach (comment) ->
    comment.defined_in = file
    comment.params = []
    comment.properties = []
    comment.ctx or comment.ctx = {}

    for tag in comment.tags
      switch tag.type
        when 'param'
          tag = processParamFlags tag
          comment.params.push tag
        when 'return'
          comment.return = tag
        when 'page'
          comment.ctx.type = 'page'
          comment.ctx.name = tag.string
        when 'restapi'
          comment.ctx.type = 'restapi'
          comment.ctx.name = tag.string

    # make parameters nested
    makeNested comment, 'params'

    if comment.ctx.type is 'property' or comment.ctx.type is 'method'
      html_id = comment.ctx.string.replace('()', '')
    else
      html_id = comment.ctx.name
    if html_id
      comment.html_id = encodeURIComponent html_id.replace(/[():\. /]/g, '_')

    switch comment.ctx.type
      when 'class'
        result.classes[comment.ctx.name] = comment
        result.ids[comment.ctx.name] = comment
        comment.filename = comment.ctx.name
      when 'property', 'method'
        if comment.ctx.hasOwnProperty 'constructor'
          result.classes[comment.ctx.constructor]?.properties.push comment
          result.ids[comment.ctx.string.replace('()', '')] = comment
          comment.filename = comment.ctx.constructor
        else if comment.ctx.receiver?
          result.classes[comment.ctx.receiver]?.properties.push comment
          result.ids[comment.ctx.string.replace('()', '')] = comment
          comment.filename = comment.ctx.receiver
      when 'page'
        result.pages[comment.ctx.name] = comment
        result.ids[comment.ctx.name] = comment
        comment.filename = 'pages'
      when 'restapi'
        result.restapis[comment.ctx.name] = comment
        result.ids[comment.ctx.name] = comment
        comment.filename = 'restapis'

copyResources = (source, target) ->
  exec = require('child_process').exec
  exec "mkdir #{target} ; cp -a #{source}/bootstrap #{source}/google-code-prettify #{source}/style.css #{target}"

generate = (paths) ->
  project_dir = process.cwd()
  doc_dir = project_dir + '/doc'
  template_dir = __dirname + '/templates'
  files = []
  paths.forEach (path) -> files.push.apply files, walkdir.sync "#{project_dir}/#{path}"

  files.forEach (file) ->
    comments = getComments file
    return if not comments?
    file = file.replace new RegExp("^" + project_dir), ''
    processComments file, comments

  copyResources __dirname, doc_dir

  result.classes = Object.keys(result.classes).sort().map (name) -> result.classes[name]
  result.pages = Object.keys(result.pages).sort().map (name) -> result.pages[name]
  result.restapis = Object.keys(result.restapis).sort( (a,b) ->
    a = a.replace /([A-Z]+) \/(.*)/, '-$2 $1'
    b = b.replace /([A-Z]+) \/(.*)/, '-$2 $1'
    if a<b then -1 else 1
  ).map (name) -> result.restapis[name]

  [].concat(result.classes, result.pages, result.restapis).forEach convertLinkComment

  fs.readFile "#{project_dir}/README.md", 'utf-8', (error, content) ->
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
        console.log file + ' is created'

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
        console.log file + ' is created'

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
        console.log file + ' is created'

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
      file = "#{doc_dir}/#{klass.ctx.name}.html"
      fs.writeFile file, result, (error) ->
        return console.error 'failed to create '+file if error
        console.log file + ' is created'

module.exports = generate
