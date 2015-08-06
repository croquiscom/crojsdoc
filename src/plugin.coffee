##
# Plugin interface
class Plugin
  ##
  # Called for each comment of sources before processing tags.
  # @param {Comment} comment
  onComment: (comment) ->
