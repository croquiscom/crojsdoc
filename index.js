if(process.env.CORMO_COVERAGE==='true') {
  require('coffee-coverage').register({path: 'relative', basePath: __dirname + '/src'});
  exports.collect = require('./src/collect');
} else {
  exports.collect = require('./lib/collect');
}
