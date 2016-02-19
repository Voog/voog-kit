'use strict';

var config = require('./config');
var fileUtils = require('./file_utils');
var path = require('path');
var _ = require('lodash');
var mime = require('mime-type/with-db');
mime.define('application/vnd.voog.design.custom+liquid', {extensions: ['tpl']}, mime.dupOverwrite);

// byName :: string -> object?
function byName(name) {
  return config.sites().filter(function(site) {
    return site.name === name || site.host === name;
  })[0];
}

// add :: object -> bool
function add(data) {
  if (_.has(data, 'host') && _.has(data, 'token')) {
    var sites = config.sites();
    sites.push(data);
    config.write('sites', sites);
    return true;
  } else {
    return false;
  };
}

// remove :: string -> bool
function remove(name) {
  var sites = config.sites();
  var siteNames = config.sites().map(function(site) {return site.name || site.host;});
  var idx = siteNames.indexOf(name);
  if (idx < 0) { return false }
  var sites = sites.slice(0, idx).concat(sites.slice(idx + 1));
  return config.write('sites', sites);
}

function getFileInfo(filePath) {
  var stat = fs.statSync(filePath);
  var fileName = path.basename(filePath);

  return {
    file: fileName,
    size: stat.size,
    contentType: mime.lookup(fileName),
    path: filePath
  };
}

// filesFor :: string -> object?
function filesFor(name) {
  var folders = [
    'assets', 'components', 'images', 'javascripts', 'layouts', 'stylesheets'
  ];

  var workingDir = dirFor(name);

  var root = fileUtils.listFiles(workingDir);

  if (root) {
    return folders.reduce(function(structure, folder) {
      if (root.indexOf(folder) >= 0) {
        var folderPath = path.join(workingDir, folder);
        structure[folder] = fileUtils.listFiles(folderPath).filter(function(file) {
          var fullPath = path.join(folderPath, file);
          var stat = fs.statSync(fullPath);

          return stat.isFile();
        }).map(function(file) {
          var fullPath = path.join(folderPath, file);

          return getFileInfo(fullPath);
        });
      }
      return structure;
    }, {});
  }
}

// dirFor :: string -> string?
function dirFor(name) {
  var site = byName(name);
  if (site) {
    return site.dir;
  }
}

// names :: * -> [string]
function names() {
  return config.sites().map(function(site) {
    return site.name || site.host;
  });
}

module.exports = {
  byName: byName,
  add: add,
  remove: remove,
  filesFor: filesFor,
  dirFor: dirFor,
  names: names
};

