# Basic

You can specify the type of a parameter like following:

```javascript
/**
 * Adds a user
 * @param {String} name the name of the user
 * @param {Number} age the age of the user
 * @return {Boolean} true if successful
 */
```
```coffeescript
##
# Adds a user
# @param {String} name the name of the user
# @param {Number} age the age of the user
# @return {Boolean} true if successful
```

The result of the above comment:

<div class='well'>
<div><p>Adds a user</p></div>
<h4>Parameters</h4><table class="table table-bordered table-condensed table-hover"><tr><th>Name</th><th>Type</th><th>Description</th></tr><tr><td><span class="method-depth0"></span><code>name</code></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a></span></td><td><span> the name of the user</span></td></tr><tr><td><span class="method-depth0"></span><code>age</code></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Number'>Number</a></span></td><td><span> the age of the user</span></td></tr></table><h4>Returns</h4><table class="table table-bordered table-condensed table-hover"><tr><th>Name</th><th>Type</th><th>Description</th></tr><tr><td>(Returns)</td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Boolean'>Boolean</a></span></td><td><span>true if successful</span></td></tr></table>
</div>

# Specifying options object

Often, JavaScript functions have an options object.
You can add a comment for this like following:

```javascript
/**
 * Defines a new property on an object.
 * @param {Object} object the object on which to define the property
 * @param {String} name the name of the property to be defined
 * @param {Object} descriptor the descriptor for the property
 * @param {Boolean} [descriptor.configurable=false] true if and only if the type of this property descriptor may be changed
 * @param [descriptor.value=undefined] the value associated with the property
 */
```
```coffeescript
##
# Defines a new property on an object.
# @param {Object} object the object on which to define the property
# @param {String} name the name of the property to be defined
# @param {Object} descriptor the descriptor for the property
# @param {Boolean} [descriptor.configurable=false] true if and only if the type of this property descriptor may be changed
# @param [descriptor.value=undefined] the value associated with the property
```

The result of the above comment:

<div class='well'>
<div><p>Defines a new property on an object.</p></div>
<h4>Parameters</h4><table class="table table-bordered table-condensed table-hover"><tr><th>Name</th><th>Type</th><th>Description</th></tr><tr><td><span class="method-depth0"></span><code>object</code></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Object'>Object</a></span></td><td><span> the object on which to define the property</span></td></tr><tr><td><span class="method-depth0"></span><code>name</code></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a></span></td><td><span> the name of the property to be defined</span></td></tr><tr><td><span class="method-depth0"></span><code>descriptor</code></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Object'>Object</a></span></td><td><span> the descriptor for the property</span></td></tr><tr><td><span class="method-depth1"></span><code>configurable=false</code><span class="pull-right label label-optional">optional</span></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Boolean'>Boolean</a></span></td><td><span> true if and only if the type of this property descriptor may be changed</span></td></tr><tr><td><span class="method-depth1"></span><code>value=undefined</code><span class="pull-right label label-optional">optional</span></td><td></td><td><span> the value associated with the property</span></td></tr></table><h4>Returns</h4><table class="table table-bordered table-condensed table-hover"><tr><td>(Nothing)</td></tr></table>
</div>

Currently, options can be nested at the maximum third levels. (eg. user.name.first_name)

# Specifying callback function

Using callback is the common pattern of JavaScript, especially in Node.js.
You can add a comment for this like following:

```javascript
/**
 * Asynchronous file open
 * @param {String} path the path to open
 * @param {String} flags flags for opening
 * @param {Number|String} [mode='0666'] file creation mode
 * @param {Function} [callback] the callback function
 * @param {Error} callback.error not null if an error is occurred
 * @param {Number} callback.fd a file descriptor
 */
```
```coffeescript
##
# Asynchronous file open
# @param {String} path the path to open
# @param {String} flags flags for opening
# @param {Number|String} [mode='0666'] file creation mode
# @param {Function} [callback] the callback function
# @param {Error} callback.error not null if an error is occurred
# @param {Number} callback.fd a file descriptor
```

The result of the above comment:

<div class='well'>
<div><p>Asynchronous file open</p></div>
<h4>Parameters</h4><table class="table table-bordered table-condensed table-hover"><tr><th>Name</th><th>Type</th><th>Description</th></tr><tr><td><span class="method-depth0"></span><code>path</code></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a></span></td><td><span> the path to open</span></td></tr><tr><td><span class="method-depth0"></span><code>flags</code></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a></span></td><td><span> flags for opening</span></td></tr><tr><td><span class="method-depth0"></span><code>mode='0666'</code><span class="pull-right label label-optional">optional</span></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Number'>Number</a>, <a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a></span></td><td><span> file creation mode</span></td></tr><tr><td><span class="method-depth0"></span><code>callback</code><span class="pull-right label label-optional">optional</span></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Function'>Function</a>(error, fd)</span></td><td><span> the callback function</span></td></tr><tr><td><span class="method-depth1"></span><code>error</code></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Error'>Error</a></span></td><td><span> not null if an error is occurred</span></td></tr><tr><td><span class="method-depth1"></span><code>fd</code></td><td><span><a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Number'>Number</a></span></td><td><span> a file descriptor</span></td></tr></table><h4>Returns</h4><table class="table table-bordered table-condensed table-hover"><tr><td>(Nothing)</td></tr></table>
</div>
