collect = require '../../lib/collect'
{expect} = require 'chai'

describe 'support various class system', ->
  checkResult = (result) ->
    expect(result.classes).to.have.length 1
    expect(result.classes[0].properties).to.have.length 4
    expect(result.classes[0].properties[0].description).to.be.eql
      summary: '<p>Create an instance</p>\n'
      body: '<p>Lorem ipsum dolor sit amet</p>\n'
      full: '<p>Create an instance</p>\n<p>Lorem ipsum dolor sit amet</p>\n'
    expect(result.classes[0].properties[0].static).to.be.eql true
    expect(result.classes[0].properties[0].ctx).to.be.eql
      type: 'method'
      name: 'createInstance'
      fullname: 'Simple.createInstance'
    expect(result.classes[0].properties[1].description).to.be.eql
      summary: '<p>Default name</p>\n'
      body: '<p>Lorem ipsum dolor sit amet</p>\n'
      full: '<p>Default name</p>\n<p>Lorem ipsum dolor sit amet</p>\n'
    expect(result.classes[0].properties[1].static).to.be.eql true
    expect(result.classes[0].properties[1].ctx).to.be.eql
      type: 'property'
      name: 'default_name'
      fullname: 'Simple.default_name'
    expect(result.classes[0].properties[2].description).to.be.eql
      summary: '<p>Say hello</p>\n'
      body: '<p>Lorem ipsum dolor sit amet</p>\n'
      full: '<p>Say hello</p>\n<p>Lorem ipsum dolor sit amet</p>\n'
    expect(result.classes[0].properties[2].static).to.be.eql false
    expect(result.classes[0].properties[2].ctx).to.be.eql
      type: 'method'
      name: 'hello'
      fullname: 'Simple::hello'
    expect(result.classes[0].properties[3].description).to.be.eql
      summary: '<p>Module name</p>\n'
      body: '<p>Lorem ipsum dolor sit amet</p>\n'
      full: '<p>Module name</p>\n<p>Lorem ipsum dolor sit amet</p>\n'
    expect(result.classes[0].properties[3].static).to.be.eql false
    expect(result.classes[0].properties[3].ctx).to.be.eql
      type: 'property'
      name: 'name'
      fullname: 'Simple::name'

  it 'Ember.js', ->
    checkResult collect [
      { path: 'simple.js', file: 'simple.js', data: """
/**
 * A simple class
 * @class
 */
var Simple = Ember.Object.extend({
  /**
   * Say hello
   *
   * Lorem ipsum dolor sit amet
   * @memberof Simple.prototype
   */
  hello: function (msg) {
  },

  /**
   * Module name
   *
   * Lorem ipsum dolor sit amet
   * @memberof Simple.prototype
   */
  name: 'default'
});

Simple.reopenClass({
  /**
   * Create an instance
   *
   * Lorem ipsum dolor sit amet
   * @memberof Simple
   */
  createInstance: function (name) {
  },

  /**
   * Default name
   *
   * Lorem ipsum dolor sit amet
   * @memberof Simple
   */
  default_name: 'default'
});
""" }
    ]

  it 'Backbone.js', ->
    checkResult collect [
      { path: 'simple.js', file: 'simple.js', data: """
/**
 * A simple class
 * @class
 */
var Simple = Backbone.Model.extend({
  /**
   * Say hello
   *
   * Lorem ipsum dolor sit amet
   * @memberof Simple.prototype
   */
  hello: function (msg) {
  },

  /**
   * Module name
   *
   * Lorem ipsum dolor sit amet
   * @memberof Simple.prototype
   */
  name: 'default'
}, {
  /**
   * Create an instance
   *
   * Lorem ipsum dolor sit amet
   * @memberof Simple
   */
  createInstance: function (name) {
  },

  /**
   * Default name
   *
   * Lorem ipsum dolor sit amet
   * @memberof Simple
   */
  default_name: 'default'
});
""" }
    ]

  it 'Ext JS', ->
    checkResult collect [
      { path: 'simple.js', file: 'simple.js', data: """
/**
 * A simple class
 * @class
 */
var Simple = new Ext.Class({
  /**
   * Say hello
   *
   * Lorem ipsum dolor sit amet
   * @memberof Simple.prototype
   */
  hello: function (msg) {
  },

  /**
   * Module name
   *
   * Lorem ipsum dolor sit amet
   * @memberof Simple.prototype
   */
  name: 'default',
  statics: {
    /**
     * Create an instance
     *
     * Lorem ipsum dolor sit amet
     * @memberof Simple
     */
    createInstance: function (name) {
    },

    /**
     * Default name
     *
     * Lorem ipsum dolor sit amet
     * @memberof Simple
     */
    default_name: 'default'
  }
});
""" }
    ]
