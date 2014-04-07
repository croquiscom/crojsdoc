##
# Generating options
#
# It is built by a config file(crojsdoc.yaml) or command line arguments
# @namespace struct
class Options
  ##
  # @property _project_dir
  # @type String
  # @private

  ##
  # @property types
  # @type Object

  ##
  # @property _sources
  # @type Array<String>

  ##
  # @property output_dir
  # @type String

  ##
  # @property title
  # @type String

  ##
  # @property quiet
  # @type Boolean

  ##
  # @property files
  # @type Boolean

  ##
  # @property _readme
  # @type String
  # @private

  ##
  # @property github
  # @type String

##
# Input to the [[#Collector]]
# @namespace struct
class Content
  ##
  # @property path
  # @type String

  ##
  # @property file
  # @type String

  ##
  # @property data
  # @type String

##
# Represents a tag in a comment
#
# Data differs by types.
#
# * types, name, description for @param
# * types, description for @return
# * local or title & url for @see
# * visibility for @api
# * types for @type
# * parent for @memberOf
# * otherClass for @augments
# * otherMemberName, thisMemberName for @borrows
# * string for other types
# @namespace struct
class Tag
  ##
  # The type of this tag
  # @property type
  # @type String

  ##
  # The remain string if this tag is unknown
  # @property string
  # @type String

  ##
  # @property types
  # @type Array<String>

  ##
  # @property name
  # @type String

  ##
  # @property description
  # @type String

##
# Represents a code context in a comment
# @namespace struct
class CodeContext
  ##
  # the type of the code.
  # One of 'function', 'declaration', 'method', 'property', or 'class'
  # @property type
  # @type String

  ##
  # the name of the function, variable, or class
  # @property name
  # @type String

  ##
  # the name of the class that has this instance property
  # @property constructor
  # @type String

  ##
  # the name of the class that has this static property
  # @property receiver
  # @type String

  ##
  # A string that represents this code best.
  #
  # * function : 'name()'
  # * declaration : 'name'
  # * class : 'class name'
  # * instance method(JavaScript) : 'class_name.prototype.name()'
  # * instance method(CoffeeScript) : 'class_name::name()'
  # * instance property(JavaScript) : 'class_name.prototype.name'
  # * instance property(CoffeeScript) : 'class_name::name'
  # * static method : 'class_name.name()'
  # * static property : 'class_name.name'
  # @property string
  # @type String

##
# Represents a comment block
# @namespace struct
class Comment
  ##
  # The first paragraph of the description
  # @property description.summary
  # @type String

  ##
  # The rest paragraphs of the description
  # @property description.body
  # @type String

  ##
  # The whole description (summary + body)
  # @property description.full
  # @type String

  ##
  # List of tags
  # @property tags
  # @type Array<Tag>

  ##
  # true if there is a tag '@api private'
  # @property isPrivate
  # @type Boolean

  ##
  # Code block follows the code
  # @property code
  # @type String

  ##
  # Code context of this comment
  # @property ctx
  # @type CodeContext

##
# Result of [[#Collector]] and input of [[#Renderer]]
# @namespace struct
class Result
