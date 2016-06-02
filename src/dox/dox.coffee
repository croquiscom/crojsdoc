##
# Module dependencies.
markdown = require 'marked'

renderer = new markdown.Renderer()

#renderer.heading = (text, level) ->
#  '<h' + level + '>' + text + '</h' + level + '>\n'

#renderer.paragraph = (text) ->
#  '<p>' + text + '</p>'

#renderer.br = () ->
#  '<br />'

markedOptions =
  renderer: renderer
  gfm: true
  tables: true
#  breaks: true
  pedantic: false
  sanitize: false
  smartLists: true
  smartypants: false

markdown.setOptions markedOptions

##
# Parse comments in the given string of `js`.
#
# @param {String} js
# @param {Object} options
# @return {Array}
# @see exports.parseComment
# @api public
exports.parseComments = (js, options = {}) ->
  js = js.replace /\r\n/gm, '\n'

  comments = []
  skipSingleStar = options.skipSingleStar
  buf = ''
  withinMultiline = false
  withinSingle = false
  withinString = false
  linterPrefixes = options.skipPrefixes or ['jslint', 'jshint', 'eshint']
  skipPattern = new RegExp('^' + (options.raw ? '' : '<p>') + '('+ linterPrefixes.join('|') + ')')
  lineNum = 1
  lineNumStarting = 1

  i = 0
  len = js.length
  while i < len
    # start comment
    if not withinMultiline and not withinSingle and not withinString and '/' is js[i] and '*' is js[i+1] and (not skipSingleStar or js[i+2] is '*')
      lineNumStarting = lineNum
      # code following the last comment
      if buf.trim().length
        comment = comments[comments.length - 1]
        if comment
          # Adjust codeStart for any vertical space between comment and code
          comment.codeStart += buf.match(/^(\s*)/)[0].split('\n').length - 1
          comment.code = code = exports.trimIndentation(buf).trim()
          comment.ctx = exports.parseCodeContext code, parentContext

          if comment.isConstructor and comment.ctx
              comment.ctx.type = 'constructor'

          # starting a new namespace
          if comment.ctx and (comment.ctx.type is 'prototype' or comment.ctx.type is 'class')
            parentContext = comment.ctx
          # reasons to clear the namespace
          # new property/method in a different constructor
          else if not parentContext or not comment.ctx or not comment.ctx.constructor or not parentContext.constructor or parentContext.constructor isnt comment.ctx.constructor
            parentContext = null
        buf = ''
      i += 2
      withinMultiline = true
      ignore = '!' is js[i]

      # if the current character isn't whitespace and isn't an ignored comment,
      # back up one character so we don't clip the contents
      if ' ' isnt js[i] and '\n' isnt js[i] and '\t' isnt js[i] and '!' isnt js[i]
        i--

    # end comment
    else if withinMultiline and not withinSingle and '*' is js[i] and '/' is js[i+1]
      i += 2
      buf = buf.replace /^[ \t]*\* ?/gm, ''
      comment = exports.parseComment buf, options
      comment.ignore = ignore
      comment.line = lineNumStarting
      comment.codeStart = lineNum + 1
      if not comment.description.full.match(skipPattern)
        comments.push comment
      withinMultiline = ignore = false
      buf = ''
    else if not withinSingle and not withinMultiline and not withinString and '/' is js[i] and '/' is js[i+1]
      withinSingle = true
      buf += js[i]
     else if withinSingle and not withinMultiline and '\n' is js[i]
      withinSingle = false
      buf += js[i]
    else if not withinSingle and not withinMultiline and ('\'' is js[i] or '"' is js[i])
      withinString = not withinString
      buf += js[i]
    else
      buf += js[i]

    if '\n' is js[i]
      lineNum++

    i++

  if comments.length is 0
    comments.push
      tags: []
      description: full: '', summary: '', body: ''
      isPrivate: false
      isConstructor: false
      line: lineNumStarting

  # trailing code
  if buf.trim().length
    comment = comments[comments.length - 1]
    # Adjust codeStart for any vertical space between comment and code
    comment.codeStart += buf.match(/^(\s*)/)[0].split('\n').length - 1
    comment.code = code = exports.trimIndentation(buf).trim()
    comment.ctx = exports.parseCodeContext code, parentContext

  comments

##
# Removes excess indentation from string of code.
#
# @param {String} str
# @return {String}
# @api public
exports.trimIndentation = (str) ->
  # Find indentation from first line of code.
  indent = str.match(/(?:^|\n)([ \t]*)[^\s]/)
  if indent
    # Replace indentation on all lines.
    str = str.replace(new RegExp('(^|\n)' + indent[1], 'g'), '$1')
  str

##
# Parse the given comment `str`.
#
# The comment object returned contains the following
#
#  - `tags`  array of tag objects
#  - `description` the first line of the comment
#  - `body` lines following the description
#  - `content` both the description and the body
#  - `isPrivate` true when "@api private" is used
#
# @param {String} str
# @param {Object} options
# @return {Object}
# @see exports.parseTag
# @api public
exports.parseComment = (str, options = {}) ->
  str = str.trim()

  comment = tags: []
  raw = options.raw
  description = {}
  tags = str.split(/\n\s*@/)

  # A comment has no description
  if tags[0].charAt(0) is '@'
    tags.unshift ''

  # parse comment body
  description.full = tags[0]
  description.summary = description.full.split('\n\n')[0]
  description.body = description.full.split('\n\n').slice(1).join('\n\n')
  comment.description = description

  # parse tags
  if tags.length
    comment.tags = tags.slice(1).map(exports.parseTag)
    comment.isPrivate = comment.tags.some (tag) ->
      'private' is tag.visibility
    comment.isConstructor = comment.tags.some (tag) ->
      'constructor' is tag.type or 'augments' is tag.type
    comment.isClass = comment.tags.some (tag) ->
      'class' is tag.type
    comment.isEvent = comment.tags.some (tag) ->
      'event' is tag.type

    if not description.full or not description.full.trim()
      comment.tags.some (tag) ->
        if 'description' is tag.type
          description.full = tag.full
          description.summary = tag.summary
          description.body = tag.body
          true

  # markdown
  if not raw
    description.full = markdown description.full
    description.summary = markdown description.summary
    description.body = markdown description.body
    comment.tags.forEach (tag) ->
      if tag.description
        tag.description = markdown tag.description
      else
        tag.html = markdown tag.string

  comment

#TODO: Find a smarter way to do this
##
# Extracts different parts of a tag by splitting string into pieces separated by whitespace. If the white spaces are
# somewhere between curly braces (which is used to indicate param/return type in JSDoc) they will not be used to split
# the string. This allows to specify jsdoc tags without the need to eliminate all white spaces i.e. {number | string}
#
# @param str The tag line as a string that needs to be split into parts
# @returns {Array.<string>} An array of strings containing the parts
exports.extractTagParts = (str) ->
  level = 0
  extract = ''
  split = []

  str.split('').forEach (c) ->
    if c.match(/\s/) and level is 0
      split.push extract
      extract = ''
    else
      if c is '{'
        level++
      else if c is '}'
        level--

      extract += c

  split.push extract
  split.filter (str) ->
    str.length > 0

##
# Parse tag string "@param {Array} name description" etc.
#
# @param {String}
# @return {Object}
# @api public
exports.parseTag = (str) ->
  tag = {}
  lines = str.split('\n')
  parts = exports.extractTagParts(lines[0])
  type = tag.type = parts.shift().replace('@', '').toLowerCase()
  matchType = new RegExp('^@?' + type + ' *')
  matchTypeStr = /^\{.+\}$/

  tag.string = str.replace(matchType, '')

  getMultilineDescription = ->
    description = parts.join ' '
    if lines.length > 1
      if description
        description += '\n'
      description += lines.slice(1).join('\n')
    description

  switch type
    when 'property', 'template', 'param'
      typeString = if matchTypeStr.test(parts[0]) then parts.shift() else ''
      tag.name = parts.shift() or ''
      tag.description = getMultilineDescription()
      exports.parseTagTypes typeString, tag
    when 'define', 'return', 'returns'
      typeString = if matchTypeStr.test(parts[0]) then parts.shift() else ''
      exports.parseTagTypes typeString, tag
      tag.description = getMultilineDescription()
    when 'see'
      if ~str.indexOf('http')
        tag.title = if parts.length > 1 then parts.shift() else ''
        tag.url = parts.join(' ')
      else
        tag.local = parts.join(' ')
    when 'api'
      tag.visibility = parts.shift()
    when 'public', 'private', 'protected'
      tag.visibility = type
    when 'enum', 'typedef', 'type'
      typeString = parts.shift()
      if not /{.*}/.test typeString
        typeString = '{' + typeString + '}'
      exports.parseTagTypes typeString, tag
    when 'lends', 'memberof'
      tag.parent = parts.shift()
    when 'extends', 'implements', 'augments'
      tag.otherClass = parts.shift()
    when 'borrows'
      tag.otherMemberName = parts.join(' ').split(' as ')[0]
      tag.thisMemberName = parts.join(' ').split(' as ')[1]
    when 'throws'
      if /{([^}]+)}\s*(.*)/.exec str
        tag.message = RegExp.$1
        tag.description = RegExp.$2
      else
        tag.message = ''
        tag.description = str
    when 'description'
      tag.full = parts.join(' ').trim()
      tag.summary = tag.full.split('\n\n')[0]
      tag.body = tag.full.split('\n\n').slice(1).join('\n\n')
    else
      tag.string = getMultilineDescription().replace(/\s+$/, '')

  tag

##
# Parse tag type string "{Array|Object}" etc.
# This function also supports complex type descriptors like in jsDoc or even the enhanced syntax used by the
# [google closure compiler](https://developers.google.com/closure/compiler/docs/js-for-compiler#types)
#
# The resulting array from the type descriptor `{number|string|{name:string,age:number|date}}` would look like this:
#
#     [
#       'number',
#       'string',
#       {
#         age: ['number', 'date'],
#         name: ['string']
#       }
#     ]
#
# @param {String} str
# @return {Array}
# @api public
exports.parseTagTypes = (str, tag) ->
  if not str
    if tag
      tag.types = []
      tag.typesDescription = ''
      tag.optional = tag.nullable = tag.nonNullable = tag.variable = false
    return []
  {parse, publish, NodeType} = require 'jsdoctypeparser'
  result = parse str.substr(1, str.length - 2)
  optional = false

  if result.type is NodeType.OPTIONAL
    optional = true
    result = result.value

  transform = (ast) ->
    if ast.type is NodeType.NAME
      [ast.name]
    else if ast.type is NodeType.UNION
      left = transform ast.left
      right = transform ast.right
      [].push.apply left, right
      left
    else if ast.type is NodeType.RECORD
      [ast.entries.reduce (obj, entry) ->
        obj[entry.key] = transform entry.value
        obj
      , {}]
    else
      [publish ast]
  types = transform result

  if tag
    tag.types = types
    #tag.typesDescription = result.toHtml()
    tag.optional = (tag.name and tag.name.slice(0,1) is '[') or optional
    #tag.nullable = result.nullable
    #tag.nonNullable = result.nonNullable
    #tag.variable = result.variable

  types

##
# Determine if a parameter is optional.
#
# Examples:
# JSDoc: {Type} [name]
# Google: {Type=} name
# TypeScript: {Type?} name
#
# @param {Object} tag
# @return {Boolean}
# @api public
exports.parseParamOptional = (tag) ->
  lastTypeChar = tag.types.slice(-1)[0].slice(-1)
  tag.name.slice(0,1) is '[' or lastTypeChar is '=' or lastTypeChar is '?'

##
# Parse the context from the given `str` of js.
#
# This method attempts to discover the context
# for the comment based on it's code. Currently
# supports:
#
#   - classes
#   - class constructors
#   - class methods
#   - function statements
#   - function expressions
#   - prototype methods
#   - prototype properties
#   - methods
#   - properties
#   - declarations
#
# @param {String} str
# @param {Object=} parentContext An indication if we are already in something. Like a namespace or an inline declaration.
# @return {Object}
# @api public
exports.parseCodeContext = (str, parentContext = {}) ->
  ctx = undefined
  # loop through all context matchers, returning the first successful match
  exports.contextPatternMatchers.some((matcher) ->
    ctx = matcher(str, parentContext)
  ) and ctx

exports.contextPatternMatchers = [
  # class, possibly exported by name or as a default
  (str) ->
    if /^\s*(export(\s+default)?\s+)?class\s+([\w$]+)(\s+extends\s+([\w$.]+(?:\(.*\))?))?\s*{/.exec(str)
      return {
        type: 'class'
        constructor: RegExp.$3
        cons: RegExp.$3
        name: RegExp.$3
        extends: RegExp.$5
        string: 'new ' + RegExp.$3 + '()'
      }
  # class constructor
  (str, parentContext) ->
    if /^\s*constructor\s*\(/.exec(str)
      return {
        type: 'constructor'
        constructor: parentContext.name
        cons: parentContext.name
        name: 'constructor'
        string: (if parentContext?.name then parentContext.name + '.prototype.' else '') + 'constructor()'
      }
  # class method
  (str, parentContext) ->
    if /^\s*(static)?\s*(\*)?\s*([\w$]+|\[.*\])\s*\(/.exec(str)
      return {
        type: 'method'
        constructor: parentContext.name
        cons: parentContext.name
        name: RegExp.$2 + RegExp.$3
        string: (if parentContext?.name then parentContext.name + (if RegExp.$1 then '.' else '.prototype.') else '') + RegExp.$2 + RegExp.$3 + '()'
      }
  # named function statementpossibly exported by name or as a default
  (str) ->
    if /^\s*(export(\s+default)?\s+)?function\s+([\w$]+)\s*\(/.exec(str)
      return {
        type: 'function'
        name: RegExp.$3
        string: RegExp.$3 + '()'
      }
  # anonymous function expression exported as a default
  (str) ->
    if /^\s*export\s+default\s+function\s*\(/.exec(str)
      return {
        type: 'function'
        name: RegExp.$1 # undefined
        string: RegExp.$1 + '()'
      }
  # function expression
  (str) ->
    if /^return\s+function(?:\s+([\w$]+))?\s*\(/.exec(str)
      return {
        type: 'function'
        name: RegExp.$1
        string: RegExp.$1 + '()'
      }
  # function expression
  (str) ->
    if /^\s*(?:const|let|var)\s+([\w$]+)\s*=\s*function/.exec(str)
      return {
        type: 'function'
        name: RegExp.$1
        string: RegExp.$1 + '()'
      }
  # prototype method
  (str, parentContext) ->
    if /^\s*([\w$.]+)\s*\.\s*prototype\s*\.\s*([\w$]+)\s*=\s*function/.exec(str)
      return {
        type: 'method'
        constructor: RegExp.$1
        cons: RegExp.$1
        name: RegExp.$2
        string: RegExp.$1 + '.prototype.' + RegExp.$2 + '()'
      }
  # prototype property
  (str) ->
    if /^\s*([\w$.]+)\s*\.\s*prototype\s*\.\s*([\w$]+)\s*=\s*([^\n;]+)/.exec(str)
      return {
        type: 'property'
        constructor: RegExp.$1
        cons: RegExp.$1
        name: RegExp.$2
        value: RegExp.$3.trim()
        string: RegExp.$1 + '.prototype.' + RegExp.$2
      }
  # prototype property without assignment
  (str) ->
    if /^\s*([\w$]+)\s*\.\s*prototype\s*\.\s*([\w$]+)\s*/.exec(str)
      return {
        type: 'property'
        constructor: RegExp.$1
        cons: RegExp.$1
        name: RegExp.$2
        string: RegExp.$1 + '.prototype.' + RegExp.$2
      }
  # inline prototype
  (str) ->
    if /^\s*([\w$.]+)\s*\.\s*prototype\s*=\s*{/.exec(str)
      return {
        type: 'prototype'
        constructor: RegExp.$1
        cons: RegExp.$1
        name: RegExp.$1
        string: RegExp.$1 + '.prototype'
      }
  # inline method
  (str, parentContext) ->
    if /^\s*([\w$.]+)\s*:\s*function/.exec(str)
      return {
        type: 'method'
        constructor: parentContext.name
        cons: parentContext.name
        name: RegExp.$1
        string: (if parentContext?.name then parentContext.name + '.prototype.' else '') + RegExp.$1 + '()'
      }
  # inline property
  (str, parentContext) ->
    if /^\s*([\w$.]+)\s*:\s*([^\n;]+)/.exec(str)
      return {
        type: 'property'
        constructor: parentContext.name
        cons: parentContext.name
        name: RegExp.$1
        value: RegExp.$2.trim()
        string: (if parentContext?.name then parentContext.name + '.' else '') + RegExp.$1
      }
  # inline getter/setter
  (str, parentContext) ->
    if /^\s*(get|set)\s*([\w$.]+)\s*\(/.exec(str)
      return {
        type: 'property'
        constructor: parentContext.name
        cons: parentContext.name
        name: RegExp.$2
        string: (if parentContext?.name then parentContext.name + '.prototype.' else '') + RegExp.$2
      }
  # method
  (str) ->
    if /^\s*([\w$.]+)\s*\.\s*([\w$]+)\s*=\s*function/.exec(str)
      return {
        type: 'method'
        receiver: RegExp.$1
        name: RegExp.$2
        string: RegExp.$1 + '.' + RegExp.$2 + '()'
      }
  # property
  (str) ->
    if /^\s*([\w$.]+)\s*\.\s*([\w$]+)\s*=\s*([^\n;]+)/.exec(str)
      return {
        type: 'property'
        receiver: RegExp.$1
        name: RegExp.$2
        value: RegExp.$3.trim()
        string: RegExp.$1 + '.' + RegExp.$2
      }
  # declaration
  (str) ->
    if /^\s*(?:const|let|var)\s+([\w$]+)\s*=\s*([^\n;]+)/.exec(str)
      return {
        type: 'declaration'
        name: RegExp.$1
        value: RegExp.$2.trim()
        string: RegExp.$1
      }
]

exports.setMarkedOptions = (opts) ->
  markdown.setOptions opts
