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

    for tag in comment.tags
      switch tag.type
        when 'param'
          tag = processParamFlags tag
          comment.params.push tag
        when 'return'
          comment.return = tag

    # make parameters nested
    makeNested comment, 'params'

    switch comment.ctx.type
      when 'class'
        comment.html_id = encodeURIComponent comment.ctx.name
        result.classes[comment.ctx.name] = comment
      when 'property', 'method'
        comment.html_id = encodeURIComponent comment.ctx.string.replace '()', ''
        if comment.ctx.hasOwnProperty 'constructor'
          result.classes[comment.ctx.constructor]?.properties.push comment
        else if comment.ctx.receiver?
          result.classes[comment.ctx.receiver]?.properties.push comment

copyResources = (source, target) ->
  exec = require('child_process').exec
  exec "cp -a #{source}/bootstrap #{target}/bootstrap"
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

  classes = Object.keys(result.classes).sort()
  classes.forEach (klass) ->
    properties = result.classes[klass].properties.sort (a, b) -> if a.ctx.name < b.ctx.name then -1 else 1
    options =
      name: klass
      klass: result.classes[klass]
      properties: properties
      classes: classes
    jade.renderFile "#{template_dir}/class.jade", options, (error, result) ->
      return console.error error.stack if error
      file = "#{doc_dir}/#{klass}.html"
      fs.writeFile file, result, (error) ->
        return console.error 'failed to create '+file if error
        console.log file + ' is created'

module.exports = generate
