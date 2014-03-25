fs = require 'fs'
spawn = require('child_process').spawn

task 'build', 'Builds JavaScript files from source', ->
  compileFiles = (dir) ->
    files = fs.readdirSync dir
    files = ("#{dir}/#{file}" for file in files when file.match /\.coffee$/)
    command = 'coffee'
    args = [ '-c', '-o', dir.replace('src', 'lib') ].concat files
    spawn command, args, stdio: 'inherit'
  compileFiles 'src'

task 'doc', 'Make documents', ->
  command = './bin/crojsdoc'
  args = []
  spawn command, args, stdio: 'inherit'
