JavaScript has the asynchronous nature, and CroJSDoc provides some tags for documentation asynchronicity.

# NodeJS style's callback

Use @nodejscallback.

```coffeescript
# (Borrowed from Node.js Manual)

##
# Asynchronously reads the entire contents of a file.
# @param {String} filename
# @param {Object} [options]
# @param {String} [options.encoding=null]
# @param {String} [options.flag='r']
# @return {String}
# @nodejscallback
readFile = (filename, options, callback) ->
  require('fs').readFile filename, options, callback

readFile 'test', encoding: 'utf-8', (error, content) ->
  console.log content
```

The result of the above comment:

<div class='well'>
<div><p>Asynchronously reads the entire contents of a file.</p></div>
<h4>Parameters</h4><table class="table table-bordered table-condensed table-hover"><tr><th>Name</th><th>Type</th><th>Description</th></tr><tr><td><span class="method-depth0"></span><code>filename</code></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a></span></td><td><span> </span></td></tr><tr><td><span class="method-depth0"></span><code>options</code><span class="pull-right label label-optional">optional</span></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Object'>Object</a></span></td><td><span> </span></td></tr><tr><td><span class="method-depth1"></span><code>encoding=null</code><span class="pull-right label label-optional">optional</span></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a></span></td><td><span> </span></td></tr><tr><td><span class="method-depth1"></span><code>flag='r'</code><span class="pull-right label label-optional">optional</span></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a></span></td><td><span> </span></td></tr><tr><td><span class="method-depth0"></span><code>callback</code></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Function'>Function</a>(error, result)</span></td><td><span> NodeJS style's callback</span></td></tr><tr><td><span class="method-depth1"></span><code>error</code></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Error'>Error</a></span></td><td><span> See throws</span></td></tr><tr><td><span class="method-depth1"></span><code>result</code></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a></span></td><td><span> See returns</span></td></tr></table><h4>Returns<small><span> as</span><span class="label label-info">NodeJS callback</span></small></h4><table class="table table-bordered table-condensed table-hover"><tr><th>Name</th><th>Type</th><th>Description</th></tr><tr><td>(Returns)</td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a></span></td><td><span></span></td></tr></table>
</div>

# Promise

Use @promise.

```coffeescript
##
# Asynchronously reads the entire contents of a file.
# @param {String} filename
# @param {Object} [options]
# @param {String} [options.encoding=null]
# @param {String} [options.flag='r']
# @return {String}
# @promise
readFile = (filename, options) ->
  Promise.promisify(require('fs').readFile) filename, options

readFile 'test', encoding: 'utf-8'
.then (content) ->
  console.log content
```

The result of the above comment:

<div class='well'>
<div><p>Asynchronously reads the entire contents of a file.</p></div>
<h4>Parameters</h4><table class="table table-bordered table-condensed table-hover"><tr><th>Name</th><th>Type</th><th>Description</th></tr><tr><td><span class="method-depth0"></span><code>filename</code></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a></span></td><td><span> </span></td></tr><tr><td><span class="method-depth0"></span><code>options</code><span class="pull-right label label-optional">optional</span></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Object'>Object</a></span></td><td><span> </span></td></tr><tr><td><span class="method-depth1"></span><code>encoding=null</code><span class="pull-right label label-optional">optional</span></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a></span></td><td><span> </span></td></tr><tr><td><span class="method-depth1"></span><code>flag='r'</code><span class="pull-right label label-optional">optional</span></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a></span></td><td><span> </span></td></tr></table><h4>Returns<small><span> as</span><span class="label label-info">Promise</span></small></h4><table class="table table-bordered table-condensed table-hover"><tr><th>Name</th><th>Type</th><th>Description</th></tr><tr><td>(Returns)</td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a></span></td><td><span></span></td></tr></table>
</div>

# Together

@nodejscallback and @promise can be used together.

```coffeescript
##
# Asynchronously reads the entire contents of a file.
# @param {String} filename
# @param {Object} [options]
# @param {String} [options.encoding=null]
# @param {String} [options.flag='r']
# @return {String}
# @nodejscallback
# @promise
readFile = (filename, options, callback) ->
  Promise.promisify(require('fs').readFile) filename, options
  .nodeify callback

readFile 'test', encoding: 'utf-8', (error, content) ->
  console.log content
# or
readFile 'test', encoding: 'utf-8'
.then (content) ->
  console.log content
```

The result of the above comment:

<div class='well'>
<div><p>Asynchronously reads the entire contents of a file.</p></div>
<h4>Parameters</h4><table class="table table-bordered table-condensed table-hover"><tr><th>Name</th><th>Type</th><th>Description</th></tr><tr><td><span class="method-depth0"></span><code>filename</code></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a></span></td><td><span> </span></td></tr><tr><td><span class="method-depth0"></span><code>options</code><span class="pull-right label label-optional">optional</span></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Object'>Object</a></span></td><td><span> </span></td></tr><tr><td><span class="method-depth1"></span><code>encoding=null</code><span class="pull-right label label-optional">optional</span></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a></span></td><td><span> </span></td></tr><tr><td><span class="method-depth1"></span><code>flag='r'</code><span class="pull-right label label-optional">optional</span></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a></span></td><td><span> </span></td></tr><tr><td><span class="method-depth0"></span><code>callback</code><span class="pull-right label label-optional">optional</span></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Function'>Function</a>(error, result)</span></td><td><span> NodeJS style's callback</span></td></tr><tr><td><span class="method-depth1"></span><code>error</code></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Error'>Error</a></span></td><td><span> See throws</span></td></tr><tr><td><span class="method-depth1"></span><code>result</code></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a></span></td><td><span> See returns</span></td></tr></table><h4>Returns<small><span> as</span><span class="label label-info">Promise</span><span class="label label-info">NodeJS callback</span></small></h4><table class="table table-bordered table-condensed table-hover"><tr><th>Name</th><th>Type</th><th>Description</th></tr><tr><td>(Returns)</td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a></span></td><td><span></span></td></tr></table>
</div>

# Use ordinary tags

If you don't use NodeJS style's callback or the function returns an other value immediately,
you can use ordinary tags.

```coffeescript
# (Borrowed from CORMO)

##
# Finds a record by id.
#
# If a callback is given, it returns the record in the callback.
# Otherwise, it returns an Query object for chaining.
# @param {RecordID} id
# @param {Function} [callback]
# @param {Error} callback.error
# @param {Model} callback.record
# @return {Query}
@find: (id, callback) ->
```

The result of the above comment:

<div class='well'>
<div><p>Finds a record by id.</p><p>If a callback is given, it returns the record in the callback. Otherwise, it returns an Query object for chaining.</p></div>
<h4>Parameters</h4><table class="table table-bordered table-condensed table-hover"><tr><th>Name</th><th>Type</th><th>Description</th></tr><tr><td><span class="method-depth0"></span><code>id</code></td><td><span>RecordID</span></td><td><span> </span></td></tr><tr><td><span class="method-depth0"></span><code>callback</code><span class="pull-right label label-optional">optional</span></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Function'>Function</a>(error, record)</span></td><td><span> </span></td></tr><tr><td><span class="method-depth1"></span><code>error</code></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Error'>Error</a></span></td><td><span> </span></td></tr><tr><td><span class="method-depth1"></span><code>record</code></td><td><span>Model</span></td><td><span> </span></td></tr></table><h4>Returns</h4><table class="table table-bordered table-condensed table-hover"><tr><th>Name</th><th>Type</th><th>Description</th></tr><tr><td>(Returns)</td><td><span>Query</span></td><td><span></span></td></tr></table>
</div>
