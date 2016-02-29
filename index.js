'use strict';

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var fs = _interopDefault(require('fs'));
var path = _interopDefault(require('path'));
var _$1 = _interopDefault(require('lodash'));
var mime = _interopDefault(require('mime-type/with-db'));
var Voog = _interopDefault(require('voog'));
var bluebird = require('bluebird');

var listFiles = function listFiles(folderPath) {
  return fs.readdirSync(folderPath).filter(function (item) {
    var itemPath = path.join(folderPath, item);
    return fs.statSync(itemPath).isFile();
  });
};

var listFolders = function listFolders(folderPath) {
  return fs.readdirSync(folderPath).filter(function (item) {
    var itemPath = path.join(folderPath, item);
    return fs.statSync(itemPath).isDirectory();
  });
};

var getFileContents = function getFileContents(filePath, options) {
  return fs.readFileSync(filePath, options);
};

var fileUtils = {
  listFiles: listFiles,
  listFolders: listFolders,
  cwd: process.cwd,
  getFileContents: getFileContents
};

var utils = {
  log: function log(data) {
    console.log(data);
  }
};

var CONFIG_FILENAME = '.voog';

var HOMEDIR = process.env.HOME;
var LOCALDIR = process.cwd();

var LOCAL_CONFIG = path.join(LOCALDIR, CONFIG_FILENAME);
var GLOBAL_CONFIG = path.join(HOMEDIR, CONFIG_FILENAME);

var siteByName = function siteByName(name, options) {
  return sites().filter(function (p) {
    return p.name === name;
  })[0];
};

var sites = function sites(options) {
  return read('sites', options) || [];
};

var write = function write(key, value, options) {
  var path = undefined;
  if (!options || _.has(options, 'global') && options.global === true) {
    path = GLOBAL_CONFIG;
  } else {
    path = LOCAL_CONFIG;
  }
  var config = read(null, options) || {};
  config[key] = value;

  var fileContents = JSON.stringify(config, null, 2);

  fs.writeFileSync(path, fileContents);
  return true;
};

var read = function read(key, options) {
  var path = undefined;
  if (!options || _.has(options, 'global') && options.global === true) {
    path = GLOBAL_CONFIG;
  } else {
    path = LOCAL_CONFIG;
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
};

var deleteKey = function deleteKey(key, options) {
  if (!options) {
    var _path = GLOBAL_CONFIG;
  } else if (options.hasOwnProperty('global') && options.global === true) {
    var _path2 = GLOBAL_CONFIG;
  } else {
    var _path3 = LOCAL_CONFIG;
  }

  var config = read(null, options);
  var deleted = delete config[key];

  if (deleted) {
    var fileContents = JSON.stringify(config);
    fs.writeFileSync(path, fileContents);
  }

  return deleted;
};

var isPresent = function isPresent(global) {
  if (global) {
    var _path4 = GLOBAL_CONFIG;
  } else {
    var _path5 = LOCAL_CONFIG;
  }
  return fs.existsSync(path);
};

var hasKey = function hasKey(key, options) {
  var config = read(null, options);
  return typeof config !== 'undefined' && config.hasOwnProperty(key);
};

var config = {
  siteByName: siteByName,
  write: write,
  read: read,
  delete: deleteKey,
  isPresent: isPresent,
  hasKey: hasKey,
  sites: sites
};

mime.define('application/vnd.voog.design.custom+liquid', { extensions: ['tpl'] }, mime.dupOverwrite);

// byName :: string -> object?
var byName = function byName(name) {
  return config.sites().filter(function (site) {
    return site.name === name || site.host === name;
  })[0];
};

// add :: object -> bool
var add = function add(data) {
  if (_$1.has(data, 'host') && _$1.has(data, 'token')) {
    var sites = config.sites();
    sites.push(data);
    config.write('sites', sites);
    return true;
  } else {
    return false;
  };
};

// remove :: string -> bool
var remove = function remove(name) {
  var sitesInConfig = config.sites();
  var siteNames = sitesInConfig.map(function (site) {
    return site.name || site.host;
  });
  var idx = siteNames.indexOf(name);
  if (idx < 0) {
    return false;
  }
  var finalSites = sitesInConfig.slice(0, idx).concat(sitesInConfig.slice(idx + 1));
  return config.write('sites', finalSites);
};

var getFileInfo = function getFileInfo(filePath) {
  var stat = fs.statSync(filePath);
  var fileName = path.basename(filePath);

  return {
    file: fileName,
    size: stat.size,
    contentType: mime.lookup(fileName),
    path: filePath
  };
};

// filesFor :: string -> object?
var filesFor = function filesFor(name) {
  var folders = ['assets', 'components', 'images', 'javascripts', 'layouts', 'stylesheets'];

  var workingDir = dirFor(name);

  var root = fileUtils.listFiles(workingDir);

  if (root) {
    return folders.reduce(function (structure, folder) {
      if (root.indexOf(folder) >= 0) {
        (function () {
          var folderPath = path.join(workingDir, folder);
          structure[folder] = fileUtils.listFiles(folderPath).filter(function (file) {
            var fullPath = path.join(folderPath, file);
            var stat = fs.statSync(fullPath);

            return stat.isFile();
          }).map(function (file) {
            var fullPath = path.join(folderPath, file);

            return getFileInfo(fullPath);
          });
        })();
      }
      return structure;
    }, {});
  }
};

// dirFor :: string -> string?
var dirFor = function dirFor(name) {
  var site = byName(name);
  if (site) {
    return site.dir || site.path;
  }
};

// hostFor :: string -> string?
var hostFor = function hostFor(name) {
  var site = byName(name);
  if (site) {
    return site.host;
  }
};

// tokenFor :: string -> string?
var tokenFor = function tokenFor(name) {
  var site = byName(name);
  if (site) {
    return site.token || site.api_token;
  }
};

// names :: * -> [string]
var names = function names() {
  return config.sites().map(function (site) {
    return site.name || site.host;
  });
};

var sites$1 = {
  byName: byName,
  add: add,
  remove: remove,
  filesFor: filesFor,
  dirFor: dirFor,
  hostFor: hostFor,
  tokenFor: tokenFor,
  names: names
};

var clientFor = function clientFor(name) {
  var host = sites$1.hostFor(name);
  var token = sites$1.tokenFor(name);

  if (host && token) {
    return new Voog(host, token);
  }
};

var getLayouts = function getLayouts(name) {
  return new bluebird.Promise(function (resolve, reject) {
    clientFor(name).layouts({}, function (err, data) {
      if (err) {
        reject(err);
      }
      resolve(data);
    });
  });
};

var getLayoutAssets = function getLayoutAssets(name) {
  return new bluebird.Promise(function (resolve, reject) {
    clientFor(name).layoutAssets({}, function (err, data) {
      if (err) {
        reject(err);
      }
      resolve(data);
    });
  });
};

var getFiles = function getFiles(name) {
  return new bluebird.Promise(function (resolve, reject) {
    bluebird.Promise.all([getLayouts(name), getLayoutAssets(name)]).then(function (layouts, assets) {
      resolve(layouts, assets);
    }, function (err) {
      reject(err);
    });
  });
};

var push = function push(files, options) {};

var actions = {
  clientFor: clientFor,
  getLayouts: getLayouts,
  getLayoutAssets: getLayoutAssets,
  getFiles: getFiles,
  push: push
};

var version = "0.0.1";

var core = {
  fileUtils: fileUtils,
  config: config,
  sites: sites$1,
  actions: actions,
  utils: utils,
  version: version
};

module.exports = core;