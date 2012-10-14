dox = require 'dox'
fs = require 'fs'
jade = require 'jade'
walkdir = require 'walkdir'

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
  classes: {}
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
        when 'restapi'
          comment.ctx.type = 'restapi'
          comment.ctx.name = tag.string

    # make parameters nested
    makeNested comment, 'params'

    switch comment.ctx.type
      when 'class'
        comment.html_id = encodeURIComponent comment.ctx.name
        result.classes[comment.ctx.name] = comment
      when 'property', 'method'
        comment.html_id = encodeURIComponent comment.ctx.string.replace('()', '').replace('::','__').replace('.','_')
        if comment.ctx.hasOwnProperty 'constructor'
          result.classes[comment.ctx.constructor]?.properties.push comment
        else if comment.ctx.receiver?
          result.classes[comment.ctx.receiver]?.properties.push comment
      when 'restapi'
        comment.html_id = encodeURIComponent comment.ctx.name.replace(/[(): /]/g, '_')
        result.restapis[comment.ctx.name] = comment

copyResources = (source, target) ->
  exec = require('child_process').exec
  exec "cp -a #{source}/bootstrap #{target}"
  exec "cp -a #{source}/style.css #{target}"

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
