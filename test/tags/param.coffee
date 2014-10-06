{collect} = require '../..'
{expect} = require 'chai'

describe 'param', ->
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
    expect(params[1]).to.be.eql
      type: 'param'
      types: ['Number']
      name: 'b'
      description: 'the second value'
