##
# Represents a comment block
# @namespace types
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
  # true if there is a tag '@api private' or '@private'
  # @property isPrivate
  # @type Boolean

  ##
  # true if there is a tag '@static'
  # @property isStatic
  # @type Boolean

  ##
  # true if there is a tag '@abstract'
  # @property isAbstract
  # @type Boolean

  ##
  # true if there is a tag '@async'
  # @property isAsync
  # @type Boolean

  ##
  # true if there is a tag '@chainable'
  # @property isChainable
  # @type Boolean

  ##
  # true if there is a tag '@promise'
  # @property doesReturnPromise
  # @type Boolean

  ##
  # true if there is a tag '@nodejscallback'
  # @property doesReturnNodejscallback
  # @type Boolean

  ##
  # Code block follows the code
  # @property code
  # @type String

  ##
  # Code context of this comment
  # @property ctx
  # @type CodeContext
