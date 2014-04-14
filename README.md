CroJSDoc is a documentation generator for JavaScript and CoffeeScript.
This works best with CoffeeScript.

This parses sources with the forked version of [dox](https://github.com/visionmedia/dox).
And Markdown comments are processed with [marked](https://github.com/chjj/marked).

See live examples on http://croquiscom.github.io/crojsdoc/ and http://croquiscom.github.io/cormo/.

# Command

```bash
$ crojsdoc [-o DIRECTORY] [-t TITLE] [-q] SOURCES...
```

* -o DIRECTORY : set output directory, default is doc
* -t TITLE : set documents title
* -q : quiet output
* SOURCES : source files or directories

Or, you can specify options in crojsdoc.yaml like this:

```
output: doc
title: Title
quite: true
sources:
  - lib
  - guides
```

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

```coffeescript
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

# Available tags

See http://croquiscom.github.io/crojsdoc/guides/ListOfTags.html

# License

The MIT License (MIT)

Copyright (c) 2012-2014 Sangmin Yoon &lt;sangmin.yoon@croquis.com&gt;

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
