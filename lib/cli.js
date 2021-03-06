// Generated by CoffeeScript 2.4.1
//#
// Provides CroJSDoc command line interface
// @module cli
var _buildOptions, _parseArguments, _readConfig, _readExternalTypes, _readSourceFiles, basename, dirname, fs, glob, isWindows, join, resolve, walkdir;

fs = require('fs');

glob = require('glob');

walkdir = require('walkdir');

({basename, dirname, join, resolve} = require('path'));

isWindows = process.platform === 'win32';

//#
// Reads a config file(crojsdoc.yaml) to build options
// @param {Options} options
// @memberOf cli
_readConfig = function(options) {
  var config, plugins, safeLoad;
  ({safeLoad} = require('js-yaml'));
  try {
    config = safeLoad(fs.readFileSync(join(process.cwd(), 'crojsdoc.yaml'), 'utf-8'));
    if (config.hasOwnProperty('output')) {
      options.output = config.output;
    }
    if (config.hasOwnProperty('title')) {
      options.title = config.title;
    }
    if (config.hasOwnProperty('quiet' || config.hasOwnProperty('quite'))) {
      options.quiet = config.quiet === true;
    }
    if (config.hasOwnProperty('files')) {
      options.files = config.files === true;
    }
    if (config.hasOwnProperty('readme') && typeof config.readme === 'string') {
      options._readme = config.readme;
    }
    if (config.hasOwnProperty('external-types')) {
      options['external-types'] = config['external-types'];
    }
    if (config.hasOwnProperty('sources')) {
      if (Array.isArray(config.sources)) {
        [].push.apply(options._sources, config.sources);
      } else {
        options._sources.push(config.sources);
      }
    }
    if (config.hasOwnProperty('github')) {
      options.github = config.github;
      if (options.github.branch === void 0) {
        options.github.branch = 'master';
      }
    }
    if (config.hasOwnProperty('reverse_see_also')) {
      options.reverse_see_also = config.reverse_see_also === true;
    }
    if (config.hasOwnProperty('plugins')) {
      plugins = config.plugins;
      if (!Array.isArray(plugins)) {
        plugins = [plugins];
      }
      options.plugins = plugins.map(function(plugin) {
        var e;
        try {
          return require(plugin);
        } catch (error) {
          e = error;
          return console.log(`Plugin '${plugin}' not found`);
        }
      }).filter(function(plugin) {
        return plugin;
      });
    }
  } catch (error) {}
};

//#
// Parses the command line arguments to build options
// @param {Options} options
// @memberOf cli
_parseArguments = function(options) {
  var OptionParser, parser, switches;
  ({OptionParser} = require('optparse'));
  switches = [['-h', '--help', 'show help'], ['-o', '--output DIRECTORY', 'Output directory'], ['-t', '--title TITLE', 'Document Title'], ['-q', '--quiet', 'less output'], ['-r', '--readme DIRECTORY', 'README.md directory path'], ['-f', '--files', 'included source files'], ['--external-types JSONFILE', 'external type definitions']];
  parser = new OptionParser(switches);
  parser.banner = 'Usage: crojsdoc [-o DIRECTORY] [-t TITLE] [-q] [options..] SOURCES...';
  parser.on('help', function() {
    console.log(parser.toString());
    return process.exit(1);
  });
  parser.on('*', function(opt, value) {
    if (value === void 0) {
      value = true;
    }
    return options[opt] = value;
  });
  return [].push.apply(options._sources, parser.parse(process.argv.slice(2)));
};

//#
// Reads additional type definitions from a file or a object
// @param {String|Object} external_types
// @param {Object} types
// @memberOf cli
_readExternalTypes = function(external_types, types) {
  var content, e, results, type, url;
  if (!external_types) {
    return;
  }
  if (typeof external_types === 'string') {
    try {
      content = fs.readFileSync(external_types, 'utf-8').trim();
      try {
        external_types = JSON.parse(content);
      } catch (error) {
        e = error;
        console.log("external-types: Invalid JSON file");
      }
    } catch (error) {
      e = error;
      console.log(`external-types: Cannot open ${external_types}`);
    }
  }
  if (typeof external_types === 'object') {
    results = [];
    for (type in external_types) {
      url = external_types[type];
      results.push(types[type] = url);
    }
    return results;
  }
};

//#
// Builds options from a config file(crojsdoc.yaml) or command line arguments
// @return {Options}
// @memberOf cli
_buildOptions = function() {
  var options;
  options = {
    _project_dir: process.cwd(),
    types: {
      // Links for pre-known types
      Object: 'https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Object',
      Boolean: 'https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Boolean',
      String: 'https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/String',
      Array: 'https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Array',
      Number: 'https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Number',
      Date: 'https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Date',
      Function: 'https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Function',
      RegExp: 'https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/RegExp',
      Error: 'https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Error',
      undefined: 'https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/undefined'
    },
    _sources: []
  };
  _readConfig(options);
  _parseArguments(options);
  if (options.plugins) {
    options.plugins.forEach(function(plugin) {
      if (plugin.externalTypes) {
        _readExternalTypes(plugin.externalTypes, options.types);
      }
    });
  }
  // process options.external-types after plugins' externalTypes
  // for user to override plugins' configurations
  _readExternalTypes(options['external-types'], options.types);
  options.output_dir = resolve(options._project_dir, options.output || 'doc');
  return options;
};

//#
// Reads source files
// @param {Options} options
// @return {Array<Content>}
// @memberOf cli
_readSourceFiles = function(options) {
  var base_path, contents, data, i, len, path, project_dir_re, ref;
  if (isWindows) {
    project_dir_re = new RegExp("^" + options._project_dir.replace(/\\/g, '\\\\'));
  } else {
    project_dir_re = new RegExp("^" + options._project_dir);
  }
  contents = [];
  ref = options._sources;
  for (i = 0, len = ref.length; i < len; i++) {
    path = ref[i];
    base_path = path = resolve(options._project_dir, path);
    while (/[*?]/.test(basename(base_path))) {
      base_path = dirname(base_path);
    }
    glob.sync(path).forEach((path) => {
      var data, file, j, len1, list;
      if (fs.statSync(path).isDirectory()) {
        list = walkdir.sync(path);
      } else {
        list = [path];
      }
      for (j = 0, len1 = list.length; j < len1; j++) {
        file = list[j];
        if (fs.statSync(file).isDirectory()) {
          continue;
        }
        data = fs.readFileSync(file, 'utf-8').trim();
        if (!data) {
          continue;
        }
        if (isWindows) {
          contents.push({
            full_path: file.replace(project_dir_re, '').replace(/\\/g, '/'),
            path: file.substr(base_path.length + 1).replace(/\\/g, '/'),
            data: data
          });
        } else {
          contents.push({
            full_path: file.replace(project_dir_re, ''),
            path: file.substr(base_path.length + 1),
            data: data
          });
        }
      }
    });
  }
  try {
    data = fs.readFileSync(`${options._readme || options._project_dir}/README.md`, 'utf-8');
    contents.push({
      full_path: '',
      path: 'README',
      data: data
    });
  } catch (error) {}
  return contents;
};

//#
// Runs CroJSDoc via CLI
// @memberOf cli
exports.run = function() {
  var contents, options, result;
  options = _buildOptions();
  contents = _readSourceFiles(options);
  result = require('./collect')(contents, options);
  return require('./render')(result, options);
};
