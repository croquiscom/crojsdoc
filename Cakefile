spawn = require('child_process').spawn

task 'doc', 'Make documents', ->
  command = './bin/crojsdoc'
  args = ['-q','--title','CroJSDoc','lib','examples']
  spawn command, args, stdio: 'inherit'
