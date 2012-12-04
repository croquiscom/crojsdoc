CroJSDoc is a documentation generator for JavaScript and CoffeeScript.
This works best with CoffeeScript.

This parses sources with the forked version of [dox](https://github.com/visionmedia/dox).
And Markdown comments are processed with [marked](https://github.com/chjj/marked).

See live examples on http://croquiscom.github.com/cormo/ and http://croquiscom.github.com/crojsdoc/.

# Command

```bash
$ crojsdoc [-q] [-o DIRECTORY] [-t TITLE] SOURCES...
```

* -q : quiet output
* -o DIRECTORY : set output directory
* -t TITLE : set documents title
* SOURCES : source files or directories

# Comment blocks

This accepts JavaDoc style's comments basically.

```javascript
/**
 * Adds two numbers
 */
function add(a, b) {
    return a+b;
}
```

For CoffeeScript, use block comments or doxygen style's comments.

```javascript
###
# Adds two numbers
###
add = (a, b) ->
    a+b

##
# Subtracts two numbers
subtract = (a, b) ->
    a-b
```

# Commands for functions

## @param

```
@param {type} name description
```

## @return

```
@return {type} description
```

## @returnprop

```
@returnprop {type} name description
```

## @throws

```
@throws {error object} description
```

# Commands for classes

## @class

```
@class name
```

## @extends

```
@extends name
```

## @uses

```
@uses name
```

## @abstract

```
@abstract
```

# Commands for methods and properties

## @memberOf

```
@memberOf name
```

## @static

```
@static
```

## @override

```
@override name
```

## @property

```
@property name
```

## @type

```
@type type
```

# Commands for REST APIs

## @restapi

```
@restapi URL
```

## @resterror

```
@resterror {code/message} description
```

# Other commands

## @private

```
@private
```

## @api

```
@api private
```

## @page

```
@page name
```

## @module

```
@module name
```

## @namespace

```
@namespace name
```

## @see 

```
@see name
```

## @todo

```
@todo description
```
