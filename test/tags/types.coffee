{collect} = require '../..'
{expect} = require 'chai'

describe 'types', ->
  it 'basic', ->
    result = collect [
      { path: 'test.coffee', file: 'test.coffee', data: """
##
# @module test

##
# Do something
# @param {String} p parameter
# @memberOf test
doSomething = (p) -> p
""" }
    ]
    expect(result.modules).to.have.length 1
    expect(result.modules[0].properties).to.have.length 1
    params = result.modules[0].properties[0].params
    expect(params).to.have.length 1
    expect(params[0]).to.eql
      type: 'param'
      string: '{String} p parameter'
      types: ['String']
      name: 'p'
      description: 'parameter'
      optional: false

  it 'parameterized type 1', ->
    result = collect [
      { path: 'test.coffee', file: 'test.coffee', data: """
##
# @module test

##
# Do something
# @param {Array.<String>} p parameter
# @memberOf test
doSomething = (p) -> p
""" }
    ]
    expect(result.modules).to.have.length 1
    expect(result.modules[0].properties).to.have.length 1
    params = result.modules[0].properties[0].params
    expect(params).to.have.length 1
    expect(params[0]).to.eql
      type: 'param'
      string: '{Array.<String>} p parameter'
      types: ['Array<String>']
      name: 'p'
      description: 'parameter'
      optional: false

  it 'parameterized type 2', ->
    result = collect [
      { path: 'test.coffee', file: 'test.coffee', data: """
##
# @module test

##
# Do something
# @param {Array<String>} p parameter
# @memberOf test
doSomething = (p) -> p
""" }
    ]
    expect(result.modules).to.have.length 1
    expect(result.modules[0].properties).to.have.length 1
    params = result.modules[0].properties[0].params
    expect(params).to.have.length 1
    expect(params[0]).to.eql
      type: 'param'
      string: '{Array<String>} p parameter'
      types: ['Array<String>']
      name: 'p'
      description: 'parameter'
      optional: false

  it 'nested parameterized type', ->
    result = collect [
      { path: 'test.coffee', file: 'test.coffee', data: """
##
# @module test

##
# Do something
# @param {StringMap<Array<String>>} p parameter
# @memberOf test
doSomething = (p) -> p
""" }
    ]
    expect(result.modules).to.have.length 1
    expect(result.modules[0].properties).to.have.length 1
    params = result.modules[0].properties[0].params
    expect(params).to.have.length 1
    expect(params[0]).to.eql
      type: 'param'
      string: '{StringMap<Array<String>>} p parameter'
      types: ['StringMap<Array<String>>']
      name: 'p'
      description: 'parameter'
      optional: false

  it 'optional', ->
    result = collect [
      { path: 'test.coffee', file: 'test.coffee', data: """
##
# @module test

##
# Do something
# @param {String=} p parameter
# @memberOf test
doSomething = (p) -> p
""" }
    ]
    expect(result.modules).to.have.length 1
    expect(result.modules[0].properties).to.have.length 1
    params = result.modules[0].properties[0].params
    expect(params).to.have.length 1
    expect(params[0]).to.eql
      type: 'param'
      string: '{String=} p parameter'
      types: ['String']
      name: 'p'
      description: 'parameter'
      optional: true

  it 'union', ->
    result = collect [
      { path: 'test.coffee', file: 'test.coffee', data: """
##
# @module test

##
# Do something
# @param {Number|String} p parameter
# @memberOf test
doSomething = (p) -> p
""" }
    ]
    expect(result.modules).to.have.length 1
    expect(result.modules[0].properties).to.have.length 1
    params = result.modules[0].properties[0].params
    expect(params).to.have.length 1
    expect(params[0]).to.eql
      type: 'param'
      string: '{Number|String} p parameter'
      types: ['Number', 'String']
      name: 'p'
      description: 'parameter'
      optional: false
