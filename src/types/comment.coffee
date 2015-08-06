##
# Represents a comment block
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
  # The code following the comment block
  # @property code
  # @type String

  ##
  # Line number where the code starts
  # @property codeStart
  # @type Number

  ##
  # The language of code. one of 'coffeescript', 'javascript' or null
  # @property language
  # @type String

  ##
  # The file path that contains this comment block relative to the project directory
  # @property full_path
  # @type String

  ##
  # The path that contains this comment block relative to the source directory
  # @property path
  # @type String

  ##
  # The context of the code block
  # @property ctx
  # @type CodeContext

  ##
  # The value of a tag '@namespace'
  # @property namespace
  # @type String
