{collect} = require '../..'
{expect} = require 'chai'

describe 'code', ->
  it 'function', ->
    result = collect [
      { path: 'test.coffee', file: 'test.coffee', data: """
##
# @module test

##
# Adds two values
# @param {Number} a the first value
# @param {Number} b the second value
# @return {Number}
# @memberOf test
sum = (a, b) ->
  a + b
""" }
    ]
    expect(result.modules).to.have.length 1
    expect(result.modules[0].properties).to.have.length 1
    property = result.modules[0].properties[0]
    expect(property.codeStart).to.eql 10
    expect(property.code).to.eql 'sum = (a, b) ->\n  a + b'

  it 'class initialize code', ->
    result = collect [
      { path: 'simple.coffee', file: 'simple.coffee', data: """
##
# A simple class
class Simple extends Super
  DEBUG = 1
  @init DEBUG

  ##
  # Create an instance
  @create: (name) ->
""" }
    ]
    expect(result.classes).to.have.length 1
    expect(result.classes[0].class_codeStart).to.eql 3
    expect(result.classes[0].class_code).to.eql 'class Simple extends Super\n  DEBUG = 1\n  @init DEBUG'

  it 'class method', ->
    result = collect [
      { path: 'simple.coffee', file: 'simple.coffee', data: """
##
# A simple class
class Simple
  ##
  # Create an instance
  @create: (name) ->
""" }
    ]
    expect(result.classes).to.have.length 1
    expect(result.classes[0].properties).to.have.length 1
    property = result.classes[0].properties[0]
    expect(property.codeStart).to.eql 6
    expect(property.code).to.eql '@create: (name) ->'
