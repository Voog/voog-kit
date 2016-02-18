'use strict';

var Promise = require('bluebird').Promise;
var fs = require('fs');

var HOMEDIR = process.env.HOME;


function getProjectByName(name, options) {
  return new Promise(function(resolve, reject) {
    if (!name || name.length === 0) { reject(); }

    readConfig(null, options).then(function(config) {
      var projects = config.projects;
      resolve(projects.filter(function(p) {
        return p.name === name;
      })[0]);
    });
  });
}

function writeConfig(key, value, options) {
  return new Promise(function(resolve, reject) {
    if (!options) {
      var path = HOMEDIR + '/.voog';
    } else if (options.hasOwnProperty('global') && options.global === true) {
      var path = HOMEDIR + '/.voog';
    } else {
      var path = './.voog';
    }

    var config = readConfig(null, options).then(function(config) {
      config[key] = value;
      var fileContents = JSON.stringify(config);

      fs.writeFile(path, fileContents, function(err) {
        if (err) { reject(err); }

        resolve(config);
      });
    });
  });
}

function readConfig(key, options) {
  return new Promise(function(resolve, reject) {
    if (!options) {
      var path = HOMEDIR + '/.voog';
    } else if (options.hasOwnProperty('global') && options.global === true) {
      var path = HOMEDIR + '/.voog';
    } else {
      var path = './.voog';
    }

    fs.readFile(path, 'utf8', function(err, data) {
      if (err) { reject(err); }

      try {
        var parsedData = JSON.parse(data);
        if (typeof key === 'string') {
          resolve(parsedData[key]);
        } else {
          resolve(parsedData);
        }
      } catch (e) {
        reject(e);
      }
    });
  });
}

function deleteKey(key, options) {
  return new Promise(function(resolve, reject) {
    if (!options) {
      var path = HOMEDIR + '/.voog';
    } else if (options.hasOwnProperty('global') && options.global === true) {
      var path = HOMEDIR + '/.voog';
    } else {
      var path = './.voog';
    }

    var config = readConfig(null, options).then(function(config) {
      delete config[key];
      var fileContents = JSON.stringify(config);

      fs.writeFile(path, fileContents, function(err) {
        if (err) { reject(err); }

        resolve(config);
      });
    });

  });
}

function createConfig(options) {
  return new Promise(function(resolve, reject) {
    if (options && options.hasOwnProperty('global') && options.global) {
      var path = HOMEDIR + '/.voog';
      var global = true;
    } else {
      var path = './.voog';
      var global = false;
    }

    if (global) {
      isPresent().then(function(globalPresent) {
        if (!globalPresent) {
          fs.writeFile(path, '', function(err) {
            if (err) { reject(err); }
            resolve('OK!');
          });
        } else {
          reject('Global configuration file already present!');
        }
      });
    } else {
      isPresent(false).then(function(localPresent) {
        if (!localPresent) {
          fs.writeFile(path, '', function(err) {
            if (err) { reject(err); }
            resolve('OK!');
          });
        } else {
          reject('Local configuration file already present!');
        }
      });
    }
  });
}

function isPresent(global) {
  return new Promise(function(resolve, reject) {
    if (global) {
      var path = HOMDEDIR + '/.voog';
    } else {
      var path = './.voog';
    }
    fs.exists(path, function(exists) {
      resolve(exists);
    });
  });
}

function hasKey(key, options) {
  return new Promise(function(resolve, reject) {
    readConfig(null, options).then(function(config) {
      resolve((typeof config !== 'undefined') && config.hasOwnProperty(key));
    });
  });
}

module.exports = {
  getProjectByName: getProjectByName,

  write: writeConfig,

  read: readConfig,

  delete: deleteKey,

  isPresent: isPresent,

  hasKey: hasKey
};

