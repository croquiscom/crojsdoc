##
# Module dependencies.
dox = require './dox'

##
# Parse comments in the given string of `coffee`.
#
# @param {String} coffee
# @param {Object} options
# @return {Array}
# @see exports.parseComment
# @api public
exports.parseCommentsCoffee = (coffee, options = {}) ->
  coffee = coffee.replace /\r\n/gm, '\n'

  comments = []
  raw = options.raw
  buf = ''
  line_number = 1
  indent = undefined
  buf_line_number = undefined

  getCodeContext = ->
    lines = buf.split('\n')
    # skip start empty lines
    while lines.length>0 and lines[0].trim() is ''
      lines.splice 0, 1
      buf_line_number++
    if lines.length isnt 0
      # get expected indent
      indentre = new RegExp('^' + lines[0].match(/^(\s*)/)[1])
      # remove 'indent' from beginning for each line
      for line, i in lines
        # skip empty line
        if line.trim() is ''
          continue
        lines[i] = line = line.replace indentre, ''
        # find line of same or little indent to stop there
        if i isnt 0 and not line.match /^\s/
          break
      # cut below lines
      lines.length = i
    code = lines.join('\n').trim()
    # add code to previous comment
    comment = comments[comments.length - 1]
    if comment
      # find parent
      i = comments.length - 2
      while i >= 0
        if comments[i].indent.search(comment.indent)<0
          break
        i--
      comment.ctx = exports.parseCodeContextCoffee code, if i>=0 then comments[i] else null
      comment.tags.forEach (tag) ->
        if tag.type is 'class'
          comment.ctx or= {}
          comment.ctx.type = 'class'
        return
      if comment.ctx and comment.ctx.type is 'class'
        comment.class_code = code
        comment.class_codeStart = buf_line_number
      else
        comment.code = code
        comment.codeStart = buf_line_number
    buf = ''

  addBuf = ->
    buf += coffee[pos]
    if '\n' is coffee[pos]
      line_number++
      return true
    return false

  addBufLine = ->
    while pos < len
      if addBuf()
        break
      pos++

  addComment = ->
    comment = dox.parseComment buf, options
    comment.ignore = ignore
    comment.indent = indent
    comments.push comment
    buf = ''
    buf_line_number = line_number

  pos = 0
  len = coffee.length
  while pos < coffee.length
    # block comment
    if coffee.slice(pos, pos+3) is '###'
      indent = buf.match(/([ \t]*)$/)[1]
      # code following previous comment
      getCodeContext()
      pos += 3
      if '\n' is coffee[pos]
        line_number++
      ignore = '!' is coffee[pos]
      pos++
      while pos < len
        if coffee.slice(pos, pos+3) is '###'
          pos += 3
          if '\n' is coffee[pos]
            line_number++
          buf = buf.replace /^[ \t]*[\*\#] ?/gm, ''
          addComment()
          break
        addBuf()
        pos++
    # doxygen style comment
    else if '#' is coffee[pos] and '#' is coffee[pos+1]
      indent = buf.match(/([ \t]*)$/)[1]
      # code following previous comment
      getCodeContext()
      pos += 2
      ignore = '!' is coffee[pos]
      if '\n' is coffee[pos]
        line_number++
      else
        pos++
        addBufLine()
      while 1
        pos++
        # check whether line comment
        j = pos
        while j < len
          if '#' is coffee[j]
            break
          if ' ' isnt coffee[j] and '\t' isnt coffee[j]
            break
          j++
        if '#' isnt coffee[j]
          buf = buf.replace /^[ \t]*#{1,2} {0,1}/gm, ''
          addComment()
          pos--
          break
        # add this line if comment
        addBufLine()
    # line comment
    else if '#' is coffee[pos]
      addBufLine()
    # buffer code
    else
      addBuf()

    pos++

  if comments.length is 0
    comments.push
      tags: [],
      description: full: '', summary: '', body: ''
      isPrivate: false

  # trailing code
  getCodeContext()

  return comments

##
# Parse the context from the given `str` of coffee.
#
# This method attempts to discover the context
# for the comment based on it's code. Currently
# supports:
#
#   - function statements
#   - function expressions
#   - prototype methods
#   - prototype properties
#   - methods
#   - properties
#   - declarations
#
# @param {String} str
# @return {Object}
# @api public
exports.parseCodeContextCoffee = (str, parent) ->
  str = str.split('\n')[0]

  # function expression
  if /^(\w+) *= *(\(.*\)|) *[-=]>/.exec(str)
    return {
      type: 'function'
      name: RegExp.$1
      string: RegExp.$1 + '()'
    }
  # prototype method
  else if /^(\w+)::(\w+) *= *(\(.*\)|) *[-=]>/.exec(str)
    return {
      type: 'method'
      constructor: RegExp.$1
      cons: RegExp.$1
      name: RegExp.$2
      string: RegExp.$1 + '::' + RegExp.$2 + '()'
    }
  # prototype property
  else if /^(\w+)::(\w+) *= *([^\n]+)/.exec(str)
    return {
      type: 'property'
      constructor: RegExp.$1
      cons: RegExp.$1
      name: RegExp.$2
      value: RegExp.$3
      string: RegExp.$1 + '::' + RegExp.$2
    }
  # method
  else if /^[\w.]*?(\w+)\.(\w+) *= *(\(.*\)|) *[-=]>/.exec(str)
    return {
      type: 'method'
      receiver: RegExp.$1
      name: RegExp.$2
      string: RegExp.$1 + '.' + RegExp.$2 + '()'
    }
  # property
  else if /^[\w.]*?(\w+)\.(\w+) *= *([^\n]+)/.exec(str)
    return {
      type: 'property'
      receiver: RegExp.$1
      name: RegExp.$2
      value: RegExp.$3
      string: RegExp.$1 + '.' + RegExp.$2
    }
  # declaration
  else if /^(\w+) *= *([^\n]+)/.exec(str)
    return {
      type: 'declaration'
      name: RegExp.$1
      value: RegExp.$2
      string: RegExp.$1
    }

  if parent and parent.ctx and parent.ctx.type is 'class'
    class_name = parent.ctx.name

  # CoffeeScript class syntax
  if /\bclass +(\w+)/.exec(str)
    return {
      type: 'class'
      name: RegExp.$1
      string: 'class ' + RegExp.$1
    }
  # prototype method
  else if /^(\w+) *: *(\(.*\)|) *[-=]>/.exec(str)
    if class_name
      return {
        type: 'method'
        constructor: class_name
        cons: class_name
        name: RegExp.$1
        string: class_name + '::' + RegExp.$1 + '()'
        is_coffeescript_constructor: RegExp.$1 is 'constructor'
      }
    else
      return {
        type: 'method'
        name: RegExp.$1
        string: RegExp.$1 + '()'
      }
  # prototype property
  else if /^(\w+) *: *([^\n]+)/.exec(str)
    if class_name
      return {
        type: 'property'
        constructor: class_name
        cons: class_name
        name: RegExp.$1
        value: RegExp.$2
        string: class_name + '::' + RegExp.$1
      }
    else
      return {
        type: 'property'
        name: RegExp.$1
        value: RegExp.$2
        string: RegExp.$1
      }
  else if not class_name
  # method
  else if /^@(\w+) *: *(\(.*\)|) *[-=]>/.exec(str)
    return {
      type: 'method'
      receiver: class_name
      name: RegExp.$1
      string: class_name + '.' + RegExp.$1 + '()'
    }
  # property
  else if /^@(\w+) *: *([^\n]+)/.exec(str)
    return {
      type: 'property'
      receiver: class_name
      name: RegExp.$1
      value: RegExp.$2
      string: class_name + '.' + RegExp.$1
    }
  else
    return {
      class_name: class_name
    }
