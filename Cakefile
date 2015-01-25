fs = require 'fs'
spawn = require('child_process').spawn

option '', '--reporter [name]', 'specify the reporter for Mocha to use'
option '', '--grep [pattern]', 'only run tests matching pattern'

task 'build', 'Builds JavaScript files from source', ->
  spawn 'npm', ['run', 'build'], stdio: 'inherit'

task 'test', 'Runs Mocha tests', (options) ->
  process.env.NODE_ENV = 'test'
  command = './node_modules/.bin/mocha'
  args = ['-R', options.reporter or 'spec', '--compilers', 'coffee:coffee-script/register']
  args.push '-g', options.grep if options.grep
  child = spawn command, args, stdio: 'inherit'

task 'test:cov', 'Gets tests coverage', (options) ->
  process.env.CORMO_COVERAGE = 'true'
  process.env.NODE_ENV = 'test'
  command = './node_modules/.bin/mocha'
  args = ['-R', 'html-cov', '--compilers', 'coffee:coffee-script/register']
  child = spawn command, args
  cov_html = fs.createWriteStream 'cov.html'
  child.stdout.on 'data', (data) ->
    cov_html.write data
  child.on 'exit', ->
    cov_html.end()

task 'doc', 'Make documents', ->
  spawn 'npm', ['run', 'doc'], stdio: 'inherit'
