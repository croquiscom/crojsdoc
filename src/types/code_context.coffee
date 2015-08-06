##
# Represents a context of a code block
class CodeContext
  ##
  # the type of the code.
  # One of 'function', 'declaration', 'method', 'property', 'constructor' or 'class'
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
  # alias of constructor
  # @property cons
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
