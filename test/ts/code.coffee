{collect} = require '../..'
{expect} = require 'chai'

describe 'code', ->
  it 'function', ->
    result = collect [
      { path: 'simple.ts', file: 'simple.ts', data: """
/**
 * @module test
 */

/**
 * Adds two values
 * @param a the first value
 * @param b the second value
 * @memberOf test
 */
function sum(a: number, b: number): number {
  return a + b;
}
""" }
    ]
    expect(result.modules).to.have.length 1
    expect(result.modules[0].properties).to.have.length 1
    property = result.modules[0].properties[0]
    expect(property.codeStart).to.eql 11
    expect(property.code).to.eql 'function sum(a: number, b: number): number {\n  return a + b;\n}'

  it 'class initialize code', ->
    result = collect [
      { path: 'simple.ts', file: 'simple.ts', data: """
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
Simple.create = function (name: string) {
};
""" }
    ]
    expect(result.classes).to.have.length 1
    expect(result.classes[0].class_codeStart).to.be.undefined
    expect(result.classes[0].class_code).to.be.undefined

  it 'class method', ->
    result = collect [
      { path: 'simple.ts', file: 'simple.ts', data: """
/**
 * A simple class
 * @class
 */
function Simple() {
}

/**
 * Create an instance
 */
Simple.create = function (name: string) {
};
""" }
    ]
    expect(result.classes).to.have.length 1
    expect(result.classes[0].properties).to.have.length 1
    property = result.classes[0].properties[0]
    expect(property.codeStart).to.eql 11
    expect(property.code).to.eql 'Simple.create = function (name: string) {\n};'
