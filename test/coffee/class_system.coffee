{collect} = require '../..'
{expect} = require 'chai'

describe 'support various class system', ->
  checkResult = (result) ->
    expect(result.classes).to.have.length 1
    expect(result.classes[0].properties).to.have.length 4
    expect(result.classes[0].properties[0].description).to.eql
      summary: '<p>Create an instance</p>\n'
      body: '<p>Lorem ipsum dolor sit amet</p>\n'
      full: '<p>Create an instance</p>\n<p>Lorem ipsum dolor sit amet</p>\n'
    expect(result.classes[0].properties[0].isStatic).to.eql true
    expect(result.classes[0].properties[0].ctx).to.eql
      type: 'method'
      name: 'createInstance'
      fullname: 'Simple.createInstance'
    expect(result.classes[0].properties[1].description).to.eql
      summary: '<p>Default name</p>\n'
      body: '<p>Lorem ipsum dolor sit amet</p>\n'
      full: '<p>Default name</p>\n<p>Lorem ipsum dolor sit amet</p>\n'
    expect(result.classes[0].properties[1].isStatic).to.eql true
    expect(result.classes[0].properties[1].ctx).to.eql
      type: 'property'
      name: 'default_name'
      fullname: 'Simple.default_name'
    expect(result.classes[0].properties[2].description).to.eql
      summary: '<p>Say hello</p>\n'
      body: '<p>Lorem ipsum dolor sit amet</p>\n'
      full: '<p>Say hello</p>\n<p>Lorem ipsum dolor sit amet</p>\n'
    expect(result.classes[0].properties[2].isStatic).to.eql false
    expect(result.classes[0].properties[2].ctx).to.eql
      type: 'method'
      name: 'hello'
      fullname: 'Simple::hello'
    expect(result.classes[0].properties[3].description).to.eql
      summary: '<p>Module name</p>\n'
      body: '<p>Lorem ipsum dolor sit amet</p>\n'
      full: '<p>Module name</p>\n<p>Lorem ipsum dolor sit amet</p>\n'
    expect(result.classes[0].properties[3].isStatic).to.eql false
    expect(result.classes[0].properties[3].ctx).to.eql
      type: 'property'
      name: 'name'
      fullname: 'Simple::name'

  it 'Ember.js', ->
    checkResult collect [
      { path: 'simple.coffee', file: 'simple.coffee', data: """
##
# A simple class
# @class
Simple = Ember.Object.extend
  ##
  # Say hello
  #
  # Lorem ipsum dolor sit amet
  hello: (msg) ->

  ##
  # Module name
  #
  # Lorem ipsum dolor sit amet
  name: 'default'

Simple.reopenClass
  ##
  # Create an instance
  #
  # Lorem ipsum dolor sit amet
  # @memberof Simple
  createInstance: (name) ->

  ##
  # Default name
  #
  # Lorem ipsum dolor sit amet
  # @memberof Simple
  default_name: 'default'
""" }
    ]

  it 'Backbone.js', ->
    checkResult collect [
      { path: 'simple.coffee', file: 'simple.coffee', data: """
##
# A simple class
# @class
Simple = Backbone.Model.extend
  ##
  # Say hello
  #
  # Lorem ipsum dolor sit amet
  hello: (msg) ->

  ##
  # Module name
  #
  # Lorem ipsum dolor sit amet
  name: 'default'
,
  ##
  # Create an instance
  #
  # Lorem ipsum dolor sit amet
  # @static
  createInstance: (name) ->

  ##
  # Default name
  #
  # Lorem ipsum dolor sit amet
  # @static
  default_name: 'default'
""" }
    ]

  it 'Ext JS', ->
    checkResult collect [
      { path: 'simple.coffee', file: 'simple.coffee', data: """
##
# A simple class
# @class
Simple = new Ext.Class
  ##
  # Say hello
  #
  # Lorem ipsum dolor sit amet
  hello: (msg) ->

  ##
  # Module name
  #
  # Lorem ipsum dolor sit amet
  name: 'default',
  statics:
    ##
    # Create an instance
    #
    # Lorem ipsum dolor sit amet
    # @memberof Simple
    createInstance: (name) ->

    ##
    # Default name
    #
    # Lorem ipsum dolor sit amet
    # @memberof Simple
    default_name: 'default'
""" }
    ]
