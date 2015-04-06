{collect} = require '../..'
{expect} = require 'chai'

describe '@chainable', ->
  it 'basic', ->
    result = collect [
      { path: 'sample.coffee', file: 'sample.coffee', data: """
##
# A sample class
class Sample
  ##
  # Assigns a setting
  # @param {String} name
  # @param {String} value
  # @chainable
  set: (name, value) ->
    return @
""" }
    ]
    expect(result.classes).to.have.length 1
    expect(result.classes[0].properties).to.have.length 1
    property = result.classes[0].properties[0]
    expect(property.return).to.be.eql
      types: ['Sample']
      description: 'this'
