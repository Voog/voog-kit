"use strict";

var fs = require("fs");
var Promise = require('bluebird').Promise;

module.exports = {
  listFiles: function(path) {
    return new Promise(function(resolve, reject) {
      fs.readdir(path, function(err, data) {
        if (err) {
          reject(err);
        }

        resolve(data);
      });
    });
  }
}
