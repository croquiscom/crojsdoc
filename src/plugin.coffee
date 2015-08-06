##
# Plugin interface
class Plugin
  ##
  # External types supported by this plugin.
  externalTypes: {}

  ##
  # Called for each comment of sources before processing tags.
  # @param {Comment} comment
  onComment: (comment) ->
