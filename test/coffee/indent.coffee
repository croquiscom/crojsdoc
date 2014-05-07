collect = require '../../lib/collect'
{expect} = require 'chai'

describe 'indent', ->
  it '2 spaces', ->
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
    expect(result.classes[0].properties[0].description).to.be.eql
      summary: '<p>Create an instance</p>\n'
      body: ''
      full: '<p>Create an instance</p>\n'

  it '2 spaces (block comment)', ->
    result = collect [
      { path: 'simple.coffee', file: 'simple.coffee', data: """
###
# A simple class
###
class Simple
  ###
  # Create an instance
  ###
  @create: (name) ->
""" }
    ]
    expect(result.classes).to.have.length 1
    expect(result.classes[0].properties).to.have.length 1
    expect(result.classes[0].properties[0].description).to.be.eql
      summary: '<p>Create an instance</p>\n'
      body: ''
      full: '<p>Create an instance</p>\n'

  it '4 spaces', ->
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
    expect(result.classes[0].properties[0].description).to.be.eql
      summary: '<p>Create an instance</p>\n'
      body: ''
      full: '<p>Create an instance</p>\n'

  it '4 spaces (block comment)', ->
    result = collect [
      { path: 'simple.coffee', file: 'simple.coffee', data: """
###
# A simple class
###
class Simple
    ###
    # Create an instance
    ###
    @create: (name) ->
""" }
    ]
    expect(result.classes).to.have.length 1
    expect(result.classes[0].properties).to.have.length 1
    expect(result.classes[0].properties[0].description).to.be.eql
      summary: '<p>Create an instance</p>\n'
      body: ''
      full: '<p>Create an instance</p>\n'

  it '1 tab', ->
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
    expect(result.classes[0].properties[0].description).to.be.eql
      summary: '<p>Create an instance</p>\n'
      body: ''
      full: '<p>Create an instance</p>\n'

  it '1 tab (block comment)', ->
    result = collect [
      { path: 'simple.coffee', file: 'simple.coffee', data: """
###
# A simple class
###
class Simple
	###
	# Create an instance
	###
	@create: (name) ->
""" }
    ]
    expect(result.classes).to.have.length 1
    expect(result.classes[0].properties).to.have.length 1
    expect(result.classes[0].properties[0].description).to.be.eql
      summary: '<p>Create an instance</p>\n'
      body: ''
      full: '<p>Create an instance</p>\n'
