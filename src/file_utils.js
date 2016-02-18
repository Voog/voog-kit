'use strict';

var fs = require('fs');

module.exports = {
  listFiles: function(path) {
    return fs.readdirSync(path);
  }
};
