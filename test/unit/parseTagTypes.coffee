{parseTagTypes} = require '../../lib/dox'
{expect} = require 'chai'

describe 'parseTagTypes', ->
  it 'simple', ->
    expect(parseTagTypes '{String}').to.eql ['String']

  it 'parameterized type 1', ->
    expect(parseTagTypes '{Array.<String>}').to.eql ['Array<String>']

  it 'parameterized type 2', ->
    expect(parseTagTypes '{Array<String>}').to.eql ['Array<String>']

  it 'nested parameterized type', ->
    expect(parseTagTypes '{StringMap<Array<String>>}').to.eql ['StringMap<Array<String>>']

  it 'union of two', ->
    expect(parseTagTypes '{Number|String}').to.eql ['Number', 'String']

  it 'union of three', ->
    expect(parseTagTypes '{Number|String|Void}').to.eql ['Number', 'String', 'Void']

  it 'record', ->
    expect(parseTagTypes '{{name: String, age: Number}}').to.eql [ { name: ['String'], age: ['Number'] } ]
