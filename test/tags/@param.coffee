{collect} = require '../..'
{expect} = require 'chai'

describe '@param', ->
  it 'basic', ->
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
sum = (a, b) -> a + b
""" }
    ]
    expect(result.modules).to.have.length 1
    expect(result.modules[0].properties).to.have.length 1
    params = result.modules[0].properties[0].params
    expect(params).to.have.length 2
    expect(params[0]).to.be.eql
      type: 'param'
      types: ['Number']
      name: 'a'
      description: 'the first value'
      optional: false
    expect(params[1]).to.be.eql
      type: 'param'
      types: ['Number']
      name: 'b'
      description: 'the second value'
      optional: false

  it 'default value', ->
    result = collect [
      { path: 'test.coffee', file: 'test.coffee', data: """
##
# @module test

##
# Do something
# @param {Number} [a=10] the first parameter
# @param {String} [b='hello'] the second parameter
# @param {Array} [c=[1,2]] the third parameter
# @memberOf test
do = (a, b, c) ->
""" }
    ]
    expect(result.modules).to.have.length 1
    expect(result.modules[0].properties).to.have.length 1
    params = result.modules[0].properties[0].params
    expect(params).to.have.length 3
    expect(params[0]).to.be.eql
      type: 'param'
      types: ['Number']
      name: 'a'
      default_value: '10'
      optional: true
      description: 'the first parameter'
    expect(params[1]).to.be.eql
      type: 'param'
      types: ['String']
      name: 'b'
      default_value: "'hello'"
      optional: true
      description: 'the second parameter'
    expect(params[2]).to.be.eql
      type: 'param'
      types: ['Array']
      name: 'c'
      default_value: "[1,2]"
      optional: true
      description: 'the third parameter'
