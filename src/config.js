'use strict';

var fs = require('fs');
var path = require('path');

var CONFIG_FILENAME = '.voog';

var HOMEDIR = process.env.HOME;
var LOCALDIR = process.cwd();

var LOCAL_CONFIG = path.join(LOCALDIR, CONFIG_FILENAME);
var GLOBAL_CONFIG = path.join(HOMEDIR, CONFIG_FILENAME);

function getSiteConfigByName(name, options) {
  return getSites().filter(function(p) {
    return p.name === name;
  })[0];
}

function getSites(options) {
  return readConfig('sites', options) || [];
}

function writeConfig(key, value, options) {
  if (!options) {
    var path = GLOBAL_CONFIG;
  } else if (options.hasOwnProperty('global') && options.global === true) {
    var path = GLOBAL_CONFIG;
  } else {
    var path = LOCAL_CONFIG;
  }

  var config = readConfig(null, options) || {};
  config[key] = value;

  var fileContents = JSON.stringify(config, null, 2);

  fs.writeFileSync(path, fileContents);
}

function readConfig(key, options) {
  if (!options) {
    var path = GLOBAL_CONFIG;
  } else if (options.hasOwnProperty('global') && options.global === true) {
    var path = GLOBAL_CONFIG;
  } else {
    var path = LOCAL_CONFIG;
  }

  try {
    var data = fs.readFileSync(path, 'utf8');
    var parsedData = JSON.parse(data);
    if (typeof key === 'string') {
      return parsedData[key];
    } else {
      return parsedData;
    }
  } catch (e) {
    return;
  }
}

function deleteKey(key, options) {
  if (!options) {
    var path = GLOBAL_CONFIG;
  } else if (options.hasOwnProperty('global') && options.global === true) {
    var path = GLOBAL_CONFIG;
  } else {
    var path = LOCAL_CONFIG;
  }

  var config = readConfig(null, options);
  var deleted = delete config[key];

  if (deleted) {
    var fileContents = JSON.stringify(config);
    fs.writeFileSync(path, fileContents);
  }

  return deleted;
}

function createConfig(options) {
  if (options && options.hasOwnProperty('global') && options.global) {
    var path = GLOBAL_CONFIG;
    var global = true;
  } else {
    var path = LOCAL_CONFIG;
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
}

function isPresent(global) {
  if (global) {
    var path = GLOBAL_CONFIG;
  } else {
    var path = LOCAL_CONFIG;
  }
  return fs.existsSync(path);
}

function hasKey(key, options) {
  var config = readConfig(null, options);
  return (typeof config !== 'undefined') && config.hasOwnProperty(key);
}

module.exports = {
  siteByName: getSiteConfigByName,

  write: writeConfig,

  read: readConfig,

  delete: deleteKey,

  isPresent: isPresent,

  hasKey: hasKey,

  sites: getSites,
};

