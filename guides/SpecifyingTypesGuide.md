# Basic

You can specify the type of a parameter like following:

```coffeescript
##
# Adds a user
# @param {String} name the name of the user
# @param {Number} age the age of the user
# @return {Boolean} true if successful
```

The result of the above comment:

<div class='well'>
<div><p>Adds a user</p></div><div></div><h4>Parameters:</h4><ul><li> <span>{<a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a>} </span><code>name</code><span> the name of the user</span></li><li> <span>{<a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Number'>Number</a>} </span><code>age</code><span> the age of the user</span></li></ul><h4>Returns:</h4><ul><li><span> {<a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Boolean'>Boolean</a>} </span><span>true if successful</span><ul></ul></li></ul>
</div>

# Specifying options object

Often, JavaScript functions have an options object.
You can add a comment for this like following:

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
<div><p>Defines a new property on an object.</p></div><div></div><h4>Parameters:</h4><ul><li> <span>{<a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Object'>Object</a>} </span><code>object</code><span> the object on which to define the property</span></li><li> <span>{<a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a>} </span><code>name</code><span> the name of the property to be defined</span></li><li> <span>{<a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Object'>Object</a>} </span><code>descriptor</code><span> the descriptor for the property</span><ul><li><span>{<a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Boolean'>Boolean</a>} </span><code>configurable=false</code><span> true if and only if the type of this property descriptor may be changed</span><span class="label label-optional">optional</span></li><li><code>value=undefined</code><span> the value associated with the property</span><span class="label label-optional">optional</span></li></ul></li></ul>
</div>

Currently, options can be nested at the maximum third levels. (eg. user.name.first_name)

# Specifying callback function

Using callback is the common pattern of JavaScript, especially in Node.js.
You can add a comment for this like following:

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
<div><p>Asynchronous file open</p></div><div></div><h4>Parameters:</h4><ul><li> <span>{<a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a>} </span><code>path</code><span> the path to open</span></li><li> <span>{<a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a>} </span><code>flags</code><span> flags for opening</span></li><li> <span>{<a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Number'>Number</a>, <a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String'>String</a>} </span><code>mode='0666'</code><span> file creation mode</span><span class="label label-optional">optional</span></li><li> <span>{<a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Function'>Function</a>(error, fd)} </span><code>callback</code><span> the callback function</span><span class="label label-optional">optional</span><ul><li><span>{<a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Error'>Error</a>} </span><code>error</code><span> not null if an error is occurred</span></li><li><span>{<a href='https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Number'>Number</a>} </span><code>fd</code><span> a file descriptor</span></li></ul></li></ul>
</div>
