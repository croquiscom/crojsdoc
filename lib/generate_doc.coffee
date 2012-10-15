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
      return "<span class='missing-link'>#{type}</span>"
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
      return "<span class='missing-link'>#{$1}</span>"
  return str

# classify type and collect id
classifyComments = (file, comments) ->
  comments.forEach (comment) ->
    comment.defined_in = file
    comment.ctx or comment.ctx = {}

    if comment.ctx.type is 'property' or comment.ctx.type is 'method'
      id = comment.ctx.string.replace('()', '')
    else
      id = comment.ctx.name
    comment.ctx.fullname = id

    for tag in comment.tags
      switch tag.type
        when 'page'
          comment.ctx.type = 'page'
          comment.ctx.name = tag.string
        when 'restapi'
          comment.ctx.type = 'restapi'
          comment.ctx.name = tag.string
        when 'class'
          comment.ctx.type = 'class'
          if tag.string
            comment.ctx.name = tag.string
        when 'memberOf'
          if /(::|#|prototype)$/.test tag.parent
            comment.ctx.constructor = tag.parent.replace /(::|#|prototype)$/, ''
            id = comment.ctx.constructor + '::' + comment.ctx.name
            comment.ctx.fullname = comment.ctx.constructor.replace(/.*[\./](\w+)/, '$1') + '::' + comment.ctx.name
          else
            comment.ctx.receiver = tag.parent
            id = comment.ctx.receiver + '.' + comment.ctx.name
            comment.ctx.fullname = comment.ctx.receiver.replace(/.*[\./](\w+)/, '$1') + '.' + comment.ctx.name
          console.log comment.ctx.fullname
        when 'param', 'return', 'returnprop', 'throws', 'resterror'
        else
          console.log "Unknown tag : #{tag.type} in #{file}"

    if id
      result.ids[id] = comment
      comment.html_id = id.replace(/[^A-Za-z0-9_]/g, '_')

    switch comment.ctx.type
      when 'class'
        result.classes[comment.ctx.name] = comment
        comment.filename = comment.ctx.name.replace(/\//g, '.')
      when 'property', 'method'
        if comment.ctx.hasOwnProperty 'constructor'
          comment.filename = comment.ctx.constructor.replace(/\//g, '.')
          comment.static = false
        else if comment.ctx.receiver?
          comment.filename = comment.ctx.receiver.replace(/\//g, '.')
          comment.static = true
      when 'page'
        comment.filename = 'pages'
      when 'restapi'
        comment.filename = 'restapis'

# structuralize comments
processComments = (comments) ->
  comments.forEach (comment) ->
    comment.params = []
    comment.returnprops = []
    comment.throws = []
    comment.resterrors = []
    comment.properties = []

    desc = comment.description
    if desc
      desc.full = convertLink desc.full
      desc.summary = convertLink desc.summary
      desc.body = convertLink desc.body

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
          res = /{([^}]+)}\s*(.*)/.exec tag.string
          if res
            comment.throws.push message: res[1], description: convertLink res[2]
        when 'resterror'
          res = /{(\d+)\/([A-Za-z0-9_ ]+)}\s*(.*)/.exec tag.string
          if res
            comment.resterrors.push code: res[1], message: res[2], description: convertLink res[3]

    # make parameters nested
    makeNested comment, 'params'
    makeNested comment, 'returnprops'

    switch comment.ctx.type
      when 'property', 'method'
        class_name = if comment.ctx.hasOwnProperty 'constructor' then comment.ctx.constructor else comment.ctx.receiver
        if class_name
          result.classes[class_name]?.properties.push comment
      when 'page'
        result.pages[comment.ctx.name] = comment
      when 'restapi'
        result.restapis[comment.ctx.name] = comment

copyResources = (source, target) ->
  exec = require('child_process').exec
  exec "mkdir #{target} ; cp -a #{source}/bootstrap #{source}/google-code-prettify #{source}/style.css #{target}"

generate = (paths) ->
  project_dir = process.cwd()
  doc_dir = project_dir + '/doc'
  template_dir = __dirname + '/templates'
  files = []
  paths.forEach (path) -> files.push.apply files, walkdir.sync "#{project_dir}/#{path}"

  all_comments = []
  files.forEach (file) ->
    comments = getComments file
    return if not comments?
    file = file.replace new RegExp("^" + project_dir), ''
    classifyComments file, comments
    all_comments.push.apply all_comments, comments

  processComments all_comments

  copyResources __dirname, doc_dir

  result.classes = Object.keys(result.classes).sort().map (name) -> result.classes[name]
  result.pages = Object.keys(result.pages).sort().map (name) -> result.pages[name]
  result.restapis = Object.keys(result.restapis).sort( (a,b) ->
    a = a.replace /([A-Z]+) \/(.*)/, '-$2 $1'
    b = b.replace /([A-Z]+) \/(.*)/, '-$2 $1'
    if a<b then -1 else 1
  ).map (name) -> result.restapis[name]

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
      file = "#{doc_dir}/#{klass.filename}.html"
      fs.writeFile file, result, (error) ->
        return console.error 'failed to create '+file if error
        console.log file + ' is created'

module.exports = generate
