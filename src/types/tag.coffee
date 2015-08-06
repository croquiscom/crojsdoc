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
  # If a typeString is added by plugins, it will be parsed to types.
  # @property typeString
  # @type String
