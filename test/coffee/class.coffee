collect = require '../../lib/collect'
{expect} = require 'chai'

describe 'class', ->
  it 'simple', ->
    result = collect [
      { path: 'simple.coffee', file: 'simple.coffee', data: """
##
# A simple class
class Simple
""" }
    ]
    expect(result.classes).to.have.length 1
    expect(result.classes[0].description).to.be.eql summary: '<p>A simple class</p>\n', full: '<p>A simple class</p>\n', body: ''

    expect(result.ids).to.have.keys 'Simple'
    expect(result.ids.Simple).to.be.equal result.classes[0]
