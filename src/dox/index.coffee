module.exports = require './dox'

dox_coffee = require './dox_coffee'
module.exports.parseCommentsCoffee = dox_coffee.parseCommentsCoffee

dox_ts = require './dox_ts'
module.exports.parseCommentsTS = dox_ts.parseCommentsTS
