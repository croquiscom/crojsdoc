{collect} = require '../..'
{expect} = require 'chai'

describe 'code', ->
  it 'function', ->
    result = collect [
      { path: 'simple.js', file: 'simple.js', data: """
/**
 * @module test
 */

/**
 * Adds two values
 * @param {Number} a the first value
 * @param {Number} b the second value
 * @return {Number}
 * @memberOf test
 */
function sum(a, b) {
  return a + b;
}
""" }
    ]
    expect(result.modules).to.have.length 1
    expect(result.modules[0].properties).to.have.length 1
    property = result.modules[0].properties[0]
    expect(property.codeStart).to.eql 12
    expect(property.code).to.eql 'function sum(a, b) {\n  return a + b;\n}'

  it 'class initialize code', ->
    result = collect [
      { path: 'simple.js', file: 'simple.js', data: """
/**
 * A simple class
 * @class
 */
function Simple() {
}

var DEBUG = 1;
Simple.init(DEBUG);

/**
 * Create an instance
 */
Simple.create = function (name) {
};
""" }
    ]
    expect(result.classes).to.have.length 1
    expect(result.classes[0].class_codeStart).to.be.undefined
    expect(result.classes[0].class_code).to.be.undefined

  it 'class method', ->
    result = collect [
      { path: 'simple.js', file: 'simple.js', data: """
/**
 * A simple class
 * @class
 */
function Simple() {
}

/**
 * Create an instance
 */
Simple.create = function (name) {
};
""" }
    ]
    expect(result.classes).to.have.length 1
    expect(result.classes[0].properties).to.have.length 1
    property = result.classes[0].properties[0]
    expect(property.codeStart).to.eql 11
    expect(property.code).to.eql 'Simple.create = function (name) {\n};'
