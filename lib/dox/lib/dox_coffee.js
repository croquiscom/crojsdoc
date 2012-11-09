/*!
 * Module dependencies.
 */

var dox = require('./dox');

/**
 * Parse comments in the given string of `coffee`.
 *
 * @param {String} coffee
 * @param {Object} options
 * @return {Array}
 * @see exports.parseComment
 * @api public
 */

exports.parseCommentsCoffee = function(coffee, options){
  options = options || {};
  coffee = coffee.replace(/\r\n/gm, '\n');

  var comments = []
    , i
    , j
    , raw = options.raw
    , comment
    , buf = ''
    , ignore
    , indent
    , line_number = 1
    , buf_line_number;

  var getCodeContext = function () {
    var lines = buf.split('\n')
      , indent
      , indentre
      , i
      , len
      , code;
    // skip start empty lines
    while (lines.length>0 && lines[0].trim()==='') {
      lines.splice(0, 1);
      buf_line_number++;
    }
    if (lines.length!==0) {
      // get expected indent
      indent = lines[0].match(/^(\s*)/)[1];
      // remove 'indent' from beginning for each line
      indentre = new RegExp('^' + indent);
      for (i = 0, len = lines.length; i < len; i++) {
        // skip empty line
        if (lines[i].trim()==='') {
          continue;
        }
        lines[i] = lines[i].replace(indentre, '');
        // find line of same or little indent to stop there
        if (i!==0 && !lines[i].match(/^\s/)) {
          break;
        }
      }
      // cut below lines
      lines.length = i;
    }
    code = lines.join('\n').trim();
    // add code to previous comment
    comment = comments[comments.length - 1];
    if (comment) {
      indent = comment.indent;
      // find parent
      for (i = comments.length - 2; i>=0 ; i--) {
        if (comments[i].indent.search(indent)<0) {
          break;
        }
      }
      comment.code = code;
      comment.line_number = buf_line_number;
      comment.ctx = exports.parseCodeContextCoffee(code, i>=0 ? comments[i] : null);
    }
    buf = '';
  };

  var addBuf = function () {
    buf += coffee[i];
    if ('\n' == coffee[i]) {
      line_number++;
      return true;
    }
    return false;
  };

  var addBufLine = function () {
    for (; i < len; i++) {
      if (addBuf(i)) {
        break;
      }
    }
  };

  var addComment = function () {
    comment = dox.parseComment(buf, options);
    comment.ignore = ignore;
    comment.indent = indent;
    comments.push(comment);
    buf = '';
    buf_line_number = line_number;
  }

  for (i = 0, len = coffee.length; i < len; ++i) {
    // block comment
    if ('#' == coffee[i] && '#' == coffee[i+1] && '#' == coffee[i+2]) {
      indent = buf.match(/([ \t]*)$/)[1];
      // code following previous comment
      getCodeContext();
      i += 3;
      if ('\n' == coffee[i]) line_number++;
      ignore = '!' == coffee[i];
      i++;
      for (; i < len; i++) {
        if ('#' == coffee[i] && '#' == coffee[i+1] && '#' == coffee[i+2]) {
          i += 3;
          if ('\n' == coffee[i]) line_number++;
          buf = buf.replace(/^ *# ?/gm, '');
          addComment();
          break;
        }
        addBuf(i);
      }
    // doxygen style comment
    } else if ('#' == coffee[i] && '#' == coffee[i+1]) {
      indent = buf.match(/([ \t]*)$/)[1];
      // code following previous comment
      getCodeContext();
      i += 2;
      ignore = '!' == coffee[i];
      if ('\n' == coffee[i]) {
        line_number++;
      } else {
        i++;
        addBufLine();
      }
      while (1) {
        i++;
        // check whether line comment
        for (var j=i; j < len; j++) {
          if ('#' == coffee[j]) {
            break;
          }
          if (' ' != coffee[j] && '\t' != coffee[j]) {
            break;
          }
        }
        if ('#' != coffee[j]) {
          buf = buf.replace(/^ *#{1,2} {0,2}/gm, '');
          addComment();
          i--;
          break;
        }
        // add this line if comment
        addBufLine();
      }
    // line comment
    } else if ('#' == coffee[i]) {
      addBufLine();
    // buffer code
    } else {
      addBuf(i);
    }
  }

  if (comments.length === 0) {
    comments.push({
      tags: [],
      description: {full: '', summary: '', body: ''},
      isPrivate: false
    });
  }

  // trailing code
  getCodeContext();

  return comments;
};

/**
 * Parse the context from the given `str` of coffee.
 *
 * This method attempts to discover the context
 * for the comment based on it's code. Currently
 * supports:
 *
 *   - function statements
 *   - function expressions
 *   - prototype methods
 *   - prototype properties
 *   - methods
 *   - properties
 *   - declarations
 *
 * @param {String} str
 * @return {Object}
 * @api public
 */

exports.parseCodeContextCoffee = function(str, parent) {
  var str = str.split('\n')[0]
    , class_name;

  // function expression
  if (/^(\w+) *= *(\(.*\)|) *[-=]>/.exec(str)) {
    return {
        type: 'function'
      , name: RegExp.$1
      , string: RegExp.$1 + '()'
    };
  // prototype method
  } else if (/^(\w+)::(\w+) *= *(\(.*\)|) *[-=]>/.exec(str)) {
    return {
        type: 'method'
      , constructor: RegExp.$1
      , name: RegExp.$2
      , string: RegExp.$1 + '::' + RegExp.$2 + '()'
    };
  // prototype property
  } else if (/^(\w+)::(\w+) *= *([^\n]+)/.exec(str)) {
    return {
        type: 'property'
      , constructor: RegExp.$1
      , name: RegExp.$2
      , value: RegExp.$3
      , string: RegExp.$1 + '::' + RegExp.$2
    };
  // method
  } else if (/^[\w.]*(\w+)\.(\w+) *= *(\(.*\)|) *[-=]>/.exec(str)) {
    return {
        type: 'method'
      , receiver: RegExp.$1
      , name: RegExp.$2
      , string: RegExp.$1 + '.' + RegExp.$2 + '()'
    };
  // property
  } else if (/^[\w.]*(\w+)\.(\w+) *= *([^\n]+)/.exec(str)) {
    return {
        type: 'property'
      , receiver: RegExp.$1
      , name: RegExp.$2
      , value: RegExp.$3
      , string: RegExp.$1 + '.' + RegExp.$2
    };
  // declaration
  } else if (/^(\w+) *= *([^\n]+)/.exec(str)) {
    return {
        type: 'declaration'
      , name: RegExp.$1
      , value: RegExp.$2
      , string: RegExp.$1
    };
  }

  if (parent && parent.ctx && parent.ctx.type==='class') {
    class_name = parent.ctx.name;
  }

  // CoffeeScript class syntax
  if (/^class +(\w+)/.exec(str)) {
    return {
        type: 'class'
      , name: RegExp.$1
      , string: 'class ' + RegExp.$1
    };
  } else if (!class_name) {
  // prototype method
  } else if (/^(\w+) *: *(\(.*\)|) *[-=]>/.exec(str)) {
    return {
        type: 'method'
      , constructor: class_name
      , name: RegExp.$1
      , string: class_name + '::' + RegExp.$1 + '()'
    };
  // prototype property
  } else if (/^(\w+) *: *([^\n]+)/.exec(str)) {
    return {
        type: 'property'
      , constructor: class_name
      , name: RegExp.$1
      , value: RegExp.$2
      , string: class_name + '::' + RegExp.$1
    };
  // method
  } else if (/^@(\w+) *: *(\(.*\)|) *[-=]>/.exec(str)) {
    return {
        type: 'method'
      , receiver: class_name
      , name: RegExp.$1
      , string: class_name + '.' + RegExp.$1 + '()'
    };
  // property
  } else if (/^@(\w+) *: *([^\n]+)/.exec(str)) {
    return {
        type: 'property'
      , receiver: class_name
      , name: RegExp.$1
      , value: RegExp.$2
      , string: class_name + '.' + RegExp.$1
    };
  } else {
    return {
        class_name: class_name
    };
  }
};
