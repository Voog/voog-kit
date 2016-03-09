'use strict';

function _interopDefault (ex) { return (ex && (typeof ex === 'object') && 'default' in ex) ? ex['default'] : ex; }

var fs = _interopDefault(require('fs'));
var path = _interopDefault(require('path'));
var _$1 = _interopDefault(require('lodash'));
var mime = _interopDefault(require('mime-type/with-db'));
var Voog = _interopDefault(require('voog'));
var request = _interopDefault(require('request'));
var bluebird = require('bluebird');

var babelHelpers = {};

babelHelpers.slicedToArray = function () {
  function sliceIterator(arr, i) {
    var _arr = [];
    var _n = true;
    var _d = false;
    var _e = undefined;

    try {
      for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) {
        _arr.push(_s.value);

        if (i && _arr.length === i) break;
      }
    } catch (err) {
      _d = true;
      _e = err;
    } finally {
      try {
        if (!_n && _i["return"]) _i["return"]();
      } finally {
        if (_d) throw _e;
      }
    }

    return _arr;
  }

  return function (arr, i) {
    if (Array.isArray(arr)) {
      return arr;
    } else if (Symbol.iterator in Object(arr)) {
      return sliceIterator(arr, i);
    } else {
      throw new TypeError("Invalid attempt to destructure non-iterable instance");
    }
  };
}();

babelHelpers;

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

var deleteFile = function deleteFile(filePath) {
  return ['fs.unlinkSync', filePath];
};

var writeFile = function writeFile(filePath, data) {
  return fs.writeFileSync(filePath, data);
};

var fileUtils = {
  listFiles: listFiles,
  listFolders: listFolders,
  deleteFile: deleteFile,
  writeFile: writeFile,
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
  return read('sites', options) || read('projects', options) || [];
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
    path: filePath,
    updatedAt: stat.mtime
  };
};

// filesFor :: string -> object?
var filesFor = function filesFor(name) {
  var folders = ['assets', 'components', 'images', 'javascripts', 'layouts', 'stylesheets'];

  var workingDir = dirFor(name);

  var root = fileUtils.listFolders(workingDir);

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

var getLayoutInfo = function getLayoutInfo(layout) {
  var name = layout.title.replace(/[^\w\.\-]/g, '_').toLowerCase();
  return {
    title: layout.title,
    layout_name: name,
    content_type: layout.content_type,
    component: layout.component,
    file: (layout.component ? 'components' : 'layouts') + '/' + name
  };
};

var getAssetInfo = function getAssetInfo(asset) {
  return {
    kind: asset.asset_type,
    filename: asset.filename,
    file: asset.asset_type + 's/' + asset.filename,
    content_type: asset.content_type
  };
};

var getManifest = function getManifest(name) {
  return new bluebird.Promise(function (resolve, reject) {
    bluebird.Promise.all([getLayouts(name), getLayoutAssets(name)]).then(function (files) {
      resolve({
        layouts: files[0].map(getLayoutInfo),
        assets: files[1].map(getAssetInfo)
      });
    }, reject);
  });
};

var writeManifest = function writeManifest(name, manifest) {
  var manifestPath = sites$1.dirFor(name) + '/manifest2.json';
  fileUtils.writeFile(manifestPath, JSON.stringify(manifest, null, 2));
};

var generateRemoteManifest = function generateRemoteManifest(name) {
  getManifest(name).then(_$1.curry(writeManifest)(name));
};

var readManifest = function readManifest(name) {
  var manifestFilePath = path.join(path.normalize(sites$1.dirFor(name)), 'manifest2.json');
  if (!fs.existsSync(manifestFilePath)) {
    return;
  }

  try {
    return JSON.parse(fs.readFileSync(manifestFilePath));
  } catch (e) {
    return;
  }
};

var getLayoutContents = function getLayoutContents(id, projectName) {
  return new bluebird.Promise(function (resolve, reject) {
    clientFor(projectName).layout(id, {}, function (err, data) {
      if (err) {
        reject(err);
      }
      resolve(data.body);
    });
  });
};

var getLayoutAssetContents = function getLayoutAssetContents(id, projectName) {
  return new bluebird.Promise(function (resolve, reject) {
    clientFor(projectName).layoutAsset(id, {}, function (err, data) {
      if (err) {
        reject(err);
      }
      if (data.editable) {
        resolve(data.data);
      } else {
        resolve(data.public_url);
      }
    });
  });
};

var getLayouts = function getLayouts(projectName) {
  var opts = arguments.length <= 1 || arguments[1] === undefined ? {} : arguments[1];

  return new bluebird.Promise(function (resolve, reject) {
    clientFor(projectName).layouts(Object.assign({}, { per_page: 250 }, opts), function (err, data) {
      if (err) {
        reject(err);
      }
      resolve(data);
    });
  });
};

var getLayoutAssets = function getLayoutAssets(projectName) {
  var opts = arguments.length <= 1 || arguments[1] === undefined ? {} : arguments[1];

  return new bluebird.Promise(function (resolve, reject) {
    clientFor(projectName).layoutAssets(Object.assign({}, { per_page: 250 }, opts), function (err, data) {
      if (err) {
        reject(err);
      }
      resolve(data);
    });
  });
};

var pullAllFiles = function pullAllFiles(projectName) {
  return new bluebird.Promise(function (resolve, reject) {
    var projectDir = sites$1.dirFor(projectName);

    bluebird.Promise.all([getLayouts(projectName), getLayoutAssets(projectName)]).then(function (_ref) {
      var _ref2 = babelHelpers.slicedToArray(_ref, 2);

      var layouts = _ref2[0];
      var assets = _ref2[1];


      bluebird.Promise.all([layouts.map(function (l) {
        var filePath = path.join(projectDir, (l.component ? 'components' : 'layouts') + '/' + normalizeTitle(l.title) + '.tpl');
        return pullFile(projectName, filePath);
      }).concat(assets.map(function (a) {
        var filePath = path.join(projectDir, (_$1.includes(['stylesheet', 'image', 'javascript'], a.asset_type) ? a.asset_type : 'asset') + 's/' + a.filename);
        return pullFile(projectName, filePath);
      }))]).then(resolve);
    });
  });
};

var pushAllFiles = function pushAllFiles(projectName) {
  return new bluebird.Promise(function (resolve, reject) {
    var projectDir = sites$1.dirFor(projectName);

    bluebird.Promise.all([getLayouts(projectName), getLayoutAssets(projectName)]).then(function (_ref3) {
      var _ref4 = babelHelpers.slicedToArray(_ref3, 2);

      var layouts = _ref4[0];
      var assets = _ref4[1];

      bluebird.Promise.all([layouts.map(function (l) {
        var filePath = path.join(projectDir, (l.component ? 'components' : 'layouts') + '/' + normalizeTitle(l.title) + '.tpl');
        return pushFile(projectName, filePath);
      }).concat(assets.filter(function (a) {
        return ['js', 'css'].indexOf(a.filename.split('.').reverse()[0]) >= 0;
      }).map(function (a) {
        var filePath = path.join(projectDir, (_$1.includes(['stylesheet', 'image', 'javascript'], a.asset_type) ? a.asset_type : 'asset') + 's/' + a.filename);
        return pushFile(projectName, filePath);
      }))]).then(resolve);
    });
  });
};

var findLayoutOrComponent = function findLayoutOrComponent(fileName, component, projectName) {
  var name = normalizeTitle(getLayoutNameFromFilename(fileName));
  return new bluebird.Promise(function (resolve, reject) {
    return clientFor(projectName).layouts({
      per_page: 250,
      'q.layout.component': component || false
    }, function (err, data) {
      if (err) {
        reject(err);
      }
      var ret = data.filter(function (l) {
        return normalizeTitle(l.title) == name;
      });
      if (ret.length === 0) {
        reject(undefined);
      }
      resolve(ret[0]);
    });
  });
};

var findLayout = function findLayout(fileName, projectName) {
  return findLayoutOrComponent(fileName, false, projectName);
};

var findLayoutAsset = function findLayoutAsset(fileName, projectName) {
  return new bluebird.Promise(function (resolve, reject) {
    return clientFor(projectName).layoutAssets({
      per_page: 250,
      'q.layout_asset.filename': fileName
    }, function (err, data) {
      if (err) {
        reject(err);
      }
      resolve(data[0]);
    });
  });
};

var getFileNameFromPath = function getFileNameFromPath(filePath) {
  return filePath.split('/')[1];
};

var getLayoutNameFromFilename = function getLayoutNameFromFilename(fileName) {
  return fileName.split('.')[0];
};

var findFile = function findFile(filePath, projectName) {
  var type = getTypeFromRelativePath(filePath);
  if (_$1.includes(['layout', 'component'], type)) {
    return findLayoutOrComponent(getLayoutNameFromFilename(getFileNameFromPath(filePath)), type == 'component', projectName);
  } else {
    return findLayoutAsset(getFileNameFromPath(filePath), projectName);
  }
};

var normalizeTitle = function normalizeTitle(title) {
  return title.replace(/[^\w\-\.]/g, '_').toLowerCase();
};

var getTypeFromRelativePath = function getTypeFromRelativePath(path) {
  var folder = path.split('/')[0];
  var folderToTypeMap = {
    'layouts': 'layout',
    'components': 'component',
    'assets': 'asset',
    'images': 'image',
    'javascripts': 'javascript',
    'stylesheets': 'stylesheet'
  };

  return folderToTypeMap[folder];
};

var normalizePath = function normalizePath(path, projectDir) {
  return path.replace(projectDir, '').replace(/^\//, '');
};

var writeFile$1 = function writeFile(projectName, file, destPath) {
  return new bluebird.Promise(function (resolve, reject) {
    if (file) {
      if (_$1.includes(Object.keys(file), 'layout_name')) {
        getLayoutContents(file.id, projectName).then(function (contents) {
          try {
            fs.mkdirSync(path.dirname(destPath));
          } catch (e) {
            if (e.code != 'EEXIST') {
              throw e;
            }
          };
          fs.writeFile(destPath, contents, function (err) {
            if (err) {
              reject(false);
            }
            resolve(true);
          });
        });
      } else if (file.editable) {
        getLayoutAssetContents(file.id, projectName).then(function (contents) {
          try {
            fs.mkdirSync(path.dirname(destPath));
          } catch (e) {
            if (e.code != 'EEXIST') {
              throw e;
            }
          };
          fs.writeFile(destPath, contents, function (err) {
            if (err) {
              reject(false);
            }
            resolve(true);
          });
        });
      } else {
        var url = file.public_url;
        try {
          fs.mkdirSync(path.dirname(destPath));
        } catch (e) {
          if (e.code != 'EEXIST') {
            throw e;
          }
        };
        var stream = fs.createWriteStream(destPath);
        if (url && stream) {
          var req = request.get(url).on('error', function (err) {
            return reject(false);
          });
          req.pipe(stream);
        } else {
          reject(false);
        }
      }
    } else {
      reject();
    }
  });
};

var uploadFile = function uploadFile(projectName, file, filePath) {
  var client = clientFor(projectName);
  return new bluebird.Promise(function (resolve, reject) {
    if (file) {
      if (_$1.includes(Object.keys(file), 'layout_name')) {
        var contents = fs.readFileSync(filePath, 'utf8');
        client.updateLayout(file.id, {
          body: contents
        }, function (err, data) {
          if (err) {
            reject(false);
          } else {
            resolve(true);
          }
        });
      } else if (file.editable) {
        var contents = fs.readFileSync(filePath, 'utf8');
        client.updateLayoutAsset(file.id, {
          data: contents
        }, function (err, data) {
          if (err) {
            reject(false);
          } else {
            resolve(true);
          }
        });
      } else {
        reject(false);
      }
    } else {
      reject();
    }
  });
};

var pullFile = function pullFile(projectName, filePath) {
  var projectDir = sites$1.dirFor(projectName);

  var normalizedPath = normalizePath(filePath, projectDir);

  return new bluebird.Promise(function (resolve, reject) {
    findFile(normalizedPath, projectName).then(function (file) {
      if (!file || typeof file === 'undefined') {
        reject();
        return;
      }

      resolve(writeFile$1(projectName, file, filePath));
    });
  });
};

var pushFile = function pushFile(projectName, filePath) {
  var projectDir = sites$1.dirFor(projectName);
  var normalizedPath = normalizePath(filePath, projectDir);

  return new bluebird.Promise(function (resolve, reject) {
    findFile(normalizedPath, projectName).then(function (file) {
      if (!file || typeof file === 'undefined') {
        reject();
        return;
      }
      resolve(uploadFile(projectName, file, filePath));
    });
  });
};

var actions = {
  clientFor: clientFor,
  pullAllFiles: pullAllFiles,
  pushAllFiles: pushAllFiles,
  findLayout: findLayout,
  findLayoutAsset: findLayoutAsset,
  pushFile: pushFile,
  pullFile: pullFile,
  getManifest: getManifest,
  readManifest: readManifest,
  writeManifest: generateRemoteManifest
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
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiaW5kZXguanMiLCJzb3VyY2VzIjpbInNyYy9maWxlX3V0aWxzLmpzIiwic3JjL3V0aWxzLmpzIiwic3JjL2NvbmZpZy5qcyIsInNyYy9zaXRlcy5qcyIsInNyYy9hY3Rpb25zLmpzIiwicGFja2FnZS5qc29uIiwic3JjL2NvcmUuanMiXSwic291cmNlc0NvbnRlbnQiOlsiJ3VzZSBzdHJpY3QnO1xuXG5pbXBvcnQgZnMgZnJvbSAnZnMnO1xuaW1wb3J0IHBhdGggZnJvbSAncGF0aCc7XG5cbmNvbnN0IGxpc3RGaWxlcyA9IChmb2xkZXJQYXRoKSA9PiB7XG4gIHJldHVybiBmcy5yZWFkZGlyU3luYyhmb2xkZXJQYXRoKS5maWx0ZXIoXG4gICAgZnVuY3Rpb24oaXRlbSkge1xuICAgIHZhciBpdGVtUGF0aCA9IHBhdGguam9pbihmb2xkZXJQYXRoLCBpdGVtKTtcbiAgICByZXR1cm4gZnMuc3RhdFN5bmMoaXRlbVBhdGgpLmlzRmlsZSgpO1xuICB9KTtcbn07XG5cbmNvbnN0IGxpc3RGb2xkZXJzID0gKGZvbGRlclBhdGgpID0+IHtcbiAgcmV0dXJuIGZzLnJlYWRkaXJTeW5jKGZvbGRlclBhdGgpLmZpbHRlcihmdW5jdGlvbihpdGVtKSB7XG4gICAgdmFyIGl0ZW1QYXRoID0gcGF0aC5qb2luKGZvbGRlclBhdGgsIGl0ZW0pO1xuICAgIHJldHVybiBmcy5zdGF0U3luYyhpdGVtUGF0aCkuaXNEaXJlY3RvcnkoKTtcbiAgfSk7XG59O1xuXG5jb25zdCBnZXRGaWxlQ29udGVudHMgPSAoZmlsZVBhdGgsIG9wdGlvbnMpID0+IHtcbiAgcmV0dXJuIGZzLnJlYWRGaWxlU3luYyhmaWxlUGF0aCwgb3B0aW9ucyk7XG59O1xuXG5jb25zdCBkZWxldGVGaWxlID0gKGZpbGVQYXRoKSA9PiB7XG4gIHJldHVybiBbJ2ZzLnVubGlua1N5bmMnLCBmaWxlUGF0aF07XG59O1xuXG5jb25zdCB3cml0ZUZpbGUgPSAoZmlsZVBhdGgsIGRhdGEpID0+IHtcbiAgcmV0dXJuIGZzLndyaXRlRmlsZVN5bmMoZmlsZVBhdGgsIGRhdGEpO1xufTtcblxuZXhwb3J0IGRlZmF1bHQge1xuICBsaXN0RmlsZXMsXG4gIGxpc3RGb2xkZXJzLFxuICBkZWxldGVGaWxlLFxuICB3cml0ZUZpbGUsXG4gIGN3ZDogcHJvY2Vzcy5jd2QsXG4gIGdldEZpbGVDb250ZW50c1xufTtcbiIsIid1c2Ugc3RyaWN0JztcblxuZXhwb3J0IGRlZmF1bHQge1xuICBsb2c6IChkYXRhKSA9PiB7XG4gICAgY29uc29sZS5sb2coZGF0YSk7XG4gIH1cbn07XG4iLCIndXNlIHN0cmljdCc7XG5cbmltcG9ydCBmcyBmcm9tICdmcyc7XG5pbXBvcnQgcGF0aCBmcm9tICdwYXRoJztcblxuY29uc3QgQ09ORklHX0ZJTEVOQU1FID0gJy52b29nJztcblxuY29uc3QgSE9NRURJUiA9IHByb2Nlc3MuZW52LkhPTUU7XG5jb25zdCBMT0NBTERJUiA9IHByb2Nlc3MuY3dkKCk7XG5cbmNvbnN0IExPQ0FMX0NPTkZJRyA9IHBhdGguam9pbihMT0NBTERJUiwgQ09ORklHX0ZJTEVOQU1FKTtcbmNvbnN0IEdMT0JBTF9DT05GSUcgPSBwYXRoLmpvaW4oSE9NRURJUiwgQ09ORklHX0ZJTEVOQU1FKTtcblxuY29uc3Qgc2l0ZUJ5TmFtZSA9IChuYW1lLCBvcHRpb25zKSA9PiB7XG4gIHJldHVybiBzaXRlcygpLmZpbHRlcihmdW5jdGlvbihwKSB7XG4gICAgcmV0dXJuIHAubmFtZSA9PT0gbmFtZTtcbiAgfSlbMF07XG59O1xuXG5jb25zdCBzaXRlcyA9IChvcHRpb25zKSA9PiB7XG4gIHJldHVybiByZWFkKCdzaXRlcycsIG9wdGlvbnMpIHx8IHJlYWQoJ3Byb2plY3RzJywgb3B0aW9ucykgfHwgW107XG59O1xuXG5jb25zdCB3cml0ZSA9IChrZXksIHZhbHVlLCBvcHRpb25zKSA9PiB7XG4gIGxldCBwYXRoO1xuICBpZiAoIW9wdGlvbnMgfHwgKF8uaGFzKG9wdGlvbnMsICdnbG9iYWwnKSAmJiBvcHRpb25zLmdsb2JhbCA9PT0gdHJ1ZSkpIHtcbiAgICBwYXRoID0gR0xPQkFMX0NPTkZJRztcbiAgfSBlbHNlIHtcbiAgICBwYXRoID0gTE9DQUxfQ09ORklHO1xuICB9XG4gIGxldCBjb25maWcgPSByZWFkKG51bGwsIG9wdGlvbnMpIHx8IHt9O1xuICBjb25maWdba2V5XSA9IHZhbHVlO1xuXG4gIGxldCBmaWxlQ29udGVudHMgPSBKU09OLnN0cmluZ2lmeShjb25maWcsIG51bGwsIDIpO1xuXG4gIGZzLndyaXRlRmlsZVN5bmMocGF0aCwgZmlsZUNvbnRlbnRzKTtcbiAgcmV0dXJuIHRydWU7XG59O1xuXG5jb25zdCByZWFkID0gKGtleSwgb3B0aW9ucykgPT4ge1xuICBsZXQgcGF0aDtcbiAgaWYgKCFvcHRpb25zIHx8IChfLmhhcyhvcHRpb25zLCAnZ2xvYmFsJykgJiYgb3B0aW9ucy5nbG9iYWwgPT09IHRydWUpKSB7XG4gICAgcGF0aCA9IEdMT0JBTF9DT05GSUc7XG4gIH0gZWxzZSB7XG4gICAgcGF0aCA9IExPQ0FMX0NPTkZJRztcbiAgfVxuXG4gIHRyeSB7XG4gICAgbGV0IGRhdGEgPSBmcy5yZWFkRmlsZVN5bmMocGF0aCwgJ3V0ZjgnKTtcbiAgICBsZXQgcGFyc2VkRGF0YSA9IEpTT04ucGFyc2UoZGF0YSk7XG4gICAgaWYgKHR5cGVvZiBrZXkgPT09ICdzdHJpbmcnKSB7XG4gICAgICByZXR1cm4gcGFyc2VkRGF0YVtrZXldO1xuICAgIH0gZWxzZSB7XG4gICAgICByZXR1cm4gcGFyc2VkRGF0YTtcbiAgICB9XG4gIH0gY2F0Y2ggKGUpIHtcbiAgICByZXR1cm47XG4gIH1cbn07XG5cbmNvbnN0IGRlbGV0ZUtleSA9IChrZXksIG9wdGlvbnMpID0+IHtcbiAgaWYgKCFvcHRpb25zKSB7XG4gICAgbGV0IHBhdGggPSBHTE9CQUxfQ09ORklHO1xuICB9IGVsc2UgaWYgKG9wdGlvbnMuaGFzT3duUHJvcGVydHkoJ2dsb2JhbCcpICYmIG9wdGlvbnMuZ2xvYmFsID09PSB0cnVlKSB7XG4gICAgbGV0IHBhdGggPSBHTE9CQUxfQ09ORklHO1xuICB9IGVsc2Uge1xuICAgIGxldCBwYXRoID0gTE9DQUxfQ09ORklHO1xuICB9XG5cbiAgbGV0IGNvbmZpZyA9IHJlYWQobnVsbCwgb3B0aW9ucyk7XG4gIGxldCBkZWxldGVkID0gZGVsZXRlIGNvbmZpZ1trZXldO1xuXG4gIGlmIChkZWxldGVkKSB7XG4gICAgbGV0IGZpbGVDb250ZW50cyA9IEpTT04uc3RyaW5naWZ5KGNvbmZpZyk7XG4gICAgZnMud3JpdGVGaWxlU3luYyhwYXRoLCBmaWxlQ29udGVudHMpO1xuICB9XG5cbiAgcmV0dXJuIGRlbGV0ZWQ7XG59O1xuXG5jb25zdCBpc1ByZXNlbnQgPSAoZ2xvYmFsKSA9PiB7XG4gIGlmIChnbG9iYWwpIHtcbiAgICBsZXQgcGF0aCA9IEdMT0JBTF9DT05GSUc7XG4gIH0gZWxzZSB7XG4gICAgbGV0IHBhdGggPSBMT0NBTF9DT05GSUc7XG4gIH1cbiAgcmV0dXJuIGZzLmV4aXN0c1N5bmMocGF0aCk7XG59O1xuXG5jb25zdCBoYXNLZXkgPSAoa2V5LCBvcHRpb25zKSA9PiB7XG4gIGxldCBjb25maWcgPSByZWFkKG51bGwsIG9wdGlvbnMpO1xuICByZXR1cm4gKHR5cGVvZiBjb25maWcgIT09ICd1bmRlZmluZWQnKSAmJiBjb25maWcuaGFzT3duUHJvcGVydHkoa2V5KTtcbn07XG5cbmV4cG9ydCBkZWZhdWx0IHtcbiAgc2l0ZUJ5TmFtZSxcbiAgd3JpdGUsXG4gIHJlYWQsXG4gIGRlbGV0ZTogZGVsZXRlS2V5LFxuICBpc1ByZXNlbnQsXG4gIGhhc0tleSxcbiAgc2l0ZXNcbn07XG5cbiIsIid1c2Ugc3RyaWN0JztcblxuaW1wb3J0IGNvbmZpZyBmcm9tICcuL2NvbmZpZyc7XG5pbXBvcnQgZmlsZVV0aWxzIGZyb20gJy4vZmlsZV91dGlscyc7XG5pbXBvcnQgcGF0aCBmcm9tICdwYXRoJztcbmltcG9ydCBfIGZyb20gJ2xvZGFzaCc7XG5pbXBvcnQgZnMgZnJvbSAnZnMnO1xuaW1wb3J0IG1pbWUgZnJvbSAnbWltZS10eXBlL3dpdGgtZGInO1xuXG5taW1lLmRlZmluZSgnYXBwbGljYXRpb24vdm5kLnZvb2cuZGVzaWduLmN1c3RvbStsaXF1aWQnLCB7ZXh0ZW5zaW9uczogWyd0cGwnXX0sIG1pbWUuZHVwT3ZlcndyaXRlKTtcblxuLy8gYnlOYW1lIDo6IHN0cmluZyAtPiBvYmplY3Q/XG5jb25zdCBieU5hbWUgPSAobmFtZSkgPT4ge1xuICByZXR1cm4gY29uZmlnLnNpdGVzKCkuZmlsdGVyKHNpdGUgPT4ge1xuICAgIHJldHVybiBzaXRlLm5hbWUgPT09IG5hbWUgfHwgc2l0ZS5ob3N0ID09PSBuYW1lO1xuICB9KVswXTtcbn07XG5cbi8vIGFkZCA6OiBvYmplY3QgLT4gYm9vbFxuY29uc3QgYWRkID0gKGRhdGEpID0+IHtcbiAgaWYgKF8uaGFzKGRhdGEsICdob3N0JykgJiYgXy5oYXMoZGF0YSwgJ3Rva2VuJykpIHtcbiAgICBsZXQgc2l0ZXMgPSBjb25maWcuc2l0ZXMoKTtcbiAgICBzaXRlcy5wdXNoKGRhdGEpO1xuICAgIGNvbmZpZy53cml0ZSgnc2l0ZXMnLCBzaXRlcyk7XG4gICAgcmV0dXJuIHRydWU7XG4gIH0gZWxzZSB7XG4gICAgcmV0dXJuIGZhbHNlO1xuICB9O1xufTtcblxuLy8gcmVtb3ZlIDo6IHN0cmluZyAtPiBib29sXG5jb25zdCByZW1vdmUgPSAobmFtZSkgPT4ge1xuICBsZXQgc2l0ZXNJbkNvbmZpZyA9IGNvbmZpZy5zaXRlcygpO1xuICBsZXQgc2l0ZU5hbWVzID0gc2l0ZXNJbkNvbmZpZy5tYXAoc2l0ZSA9PiBzaXRlLm5hbWUgfHwgc2l0ZS5ob3N0KTtcbiAgbGV0IGlkeCA9IHNpdGVOYW1lcy5pbmRleE9mKG5hbWUpO1xuICBpZiAoaWR4IDwgMCkgeyByZXR1cm4gZmFsc2U7IH1cbiAgbGV0IGZpbmFsU2l0ZXMgPSBzaXRlc0luQ29uZmlnLnNsaWNlKDAsIGlkeCkuY29uY2F0KHNpdGVzSW5Db25maWcuc2xpY2UoaWR4ICsgMSkpO1xuICByZXR1cm4gY29uZmlnLndyaXRlKCdzaXRlcycsIGZpbmFsU2l0ZXMpO1xufTtcblxuY29uc3QgZ2V0RmlsZUluZm8gPSAoZmlsZVBhdGgpID0+IHtcbiAgbGV0IHN0YXQgPSBmcy5zdGF0U3luYyhmaWxlUGF0aCk7XG4gIGxldCBmaWxlTmFtZSA9IHBhdGguYmFzZW5hbWUoZmlsZVBhdGgpO1xuICByZXR1cm4ge1xuICAgIGZpbGU6IGZpbGVOYW1lLFxuICAgIHNpemU6IHN0YXQuc2l6ZSxcbiAgICBjb250ZW50VHlwZTogbWltZS5sb29rdXAoZmlsZU5hbWUpLFxuICAgIHBhdGg6IGZpbGVQYXRoLFxuICAgIHVwZGF0ZWRBdDogc3RhdC5tdGltZVxuICB9O1xufTtcblxuLy8gZmlsZXNGb3IgOjogc3RyaW5nIC0+IG9iamVjdD9cbmNvbnN0IGZpbGVzRm9yID0gKG5hbWUpID0+IHtcbiAgbGV0IGZvbGRlcnMgPSBbXG4gICAgJ2Fzc2V0cycsICdjb21wb25lbnRzJywgJ2ltYWdlcycsICdqYXZhc2NyaXB0cycsICdsYXlvdXRzJywgJ3N0eWxlc2hlZXRzJ1xuICBdO1xuXG4gIGxldCB3b3JraW5nRGlyID0gZGlyRm9yKG5hbWUpO1xuXG4gIGxldCByb290ID0gZmlsZVV0aWxzLmxpc3RGb2xkZXJzKHdvcmtpbmdEaXIpO1xuXG4gIGlmIChyb290KSB7XG4gICAgcmV0dXJuIGZvbGRlcnMucmVkdWNlKGZ1bmN0aW9uKHN0cnVjdHVyZSwgZm9sZGVyKSB7XG4gICAgICBpZiAocm9vdC5pbmRleE9mKGZvbGRlcikgPj0gMCkge1xuICAgICAgICBsZXQgZm9sZGVyUGF0aCA9IHBhdGguam9pbih3b3JraW5nRGlyLCBmb2xkZXIpO1xuICAgICAgICBzdHJ1Y3R1cmVbZm9sZGVyXSA9IGZpbGVVdGlscy5saXN0RmlsZXMoZm9sZGVyUGF0aCkuZmlsdGVyKGZ1bmN0aW9uKGZpbGUpIHtcbiAgICAgICAgICBsZXQgZnVsbFBhdGggPSBwYXRoLmpvaW4oZm9sZGVyUGF0aCwgZmlsZSk7XG4gICAgICAgICAgbGV0IHN0YXQgPSBmcy5zdGF0U3luYyhmdWxsUGF0aCk7XG5cbiAgICAgICAgICByZXR1cm4gc3RhdC5pc0ZpbGUoKTtcbiAgICAgICAgfSkubWFwKGZ1bmN0aW9uKGZpbGUpIHtcbiAgICAgICAgICBsZXQgZnVsbFBhdGggPSBwYXRoLmpvaW4oZm9sZGVyUGF0aCwgZmlsZSk7XG5cbiAgICAgICAgICByZXR1cm4gZ2V0RmlsZUluZm8oZnVsbFBhdGgpO1xuICAgICAgICB9KTtcbiAgICAgIH1cbiAgICAgIHJldHVybiBzdHJ1Y3R1cmU7XG4gICAgfSwge30pO1xuICB9XG59O1xuXG4vLyBkaXJGb3IgOjogc3RyaW5nIC0+IHN0cmluZz9cbmNvbnN0IGRpckZvciA9IChuYW1lKSA9PiB7XG4gIGxldCBzaXRlID0gYnlOYW1lKG5hbWUpO1xuICBpZiAoc2l0ZSkge1xuICAgIHJldHVybiBzaXRlLmRpciB8fCBzaXRlLnBhdGg7XG4gIH1cbn07XG5cbi8vIGhvc3RGb3IgOjogc3RyaW5nIC0+IHN0cmluZz9cbmNvbnN0IGhvc3RGb3IgPSAobmFtZSkgPT4ge1xuICBsZXQgc2l0ZSA9IGJ5TmFtZShuYW1lKTtcbiAgaWYgKHNpdGUpIHtcbiAgICByZXR1cm4gc2l0ZS5ob3N0O1xuICB9XG59O1xuXG4vLyB0b2tlbkZvciA6OiBzdHJpbmcgLT4gc3RyaW5nP1xuY29uc3QgdG9rZW5Gb3IgPSAobmFtZSkgPT4ge1xuICBsZXQgc2l0ZSA9IGJ5TmFtZShuYW1lKTtcbiAgaWYgKHNpdGUpIHtcbiAgICByZXR1cm4gc2l0ZS50b2tlbiB8fCBzaXRlLmFwaV90b2tlbjtcbiAgfVxufTtcblxuLy8gbmFtZXMgOjogKiAtPiBbc3RyaW5nXVxuY29uc3QgbmFtZXMgPSAoKSA9PiB7XG4gIHJldHVybiBjb25maWcuc2l0ZXMoKS5tYXAoZnVuY3Rpb24oc2l0ZSkge1xuICAgIHJldHVybiBzaXRlLm5hbWUgfHwgc2l0ZS5ob3N0O1xuICB9KTtcbn07XG5cbmV4cG9ydCBkZWZhdWx0IHtcbiAgYnlOYW1lLFxuICBhZGQsXG4gIHJlbW92ZSxcbiAgZmlsZXNGb3IsXG4gIGRpckZvcixcbiAgaG9zdEZvcixcbiAgdG9rZW5Gb3IsXG4gIG5hbWVzXG59O1xuXG4iLCIndXNlIHN0cmljdCc7XG5cbmltcG9ydCBjb25maWcgZnJvbSAnLi9jb25maWcnO1xuaW1wb3J0IHNpdGVzIGZyb20gJy4vc2l0ZXMnO1xuaW1wb3J0IFZvb2cgZnJvbSAndm9vZyc7XG5pbXBvcnQgZmlsZVV0aWxzIGZyb20gJy4vZmlsZV91dGlscyc7XG5pbXBvcnQgZnMgZnJvbSAnZnMnO1xuaW1wb3J0IF8gZnJvbSAnbG9kYXNoJztcbmltcG9ydCByZXF1ZXN0IGZyb20gJ3JlcXVlc3QnO1xuaW1wb3J0IHBhdGggZnJvbSAncGF0aCc7XG5pbXBvcnQge1Byb21pc2V9IGZyb20gJ2JsdWViaXJkJztcblxuY29uc3QgTEFZT1VURk9MREVSUyA9IFsnY29tcG9uZW50cycsICdsYXlvdXRzJ107XG5jb25zdCBBU1NFVEZPTERFUlMgPSBbJ2Fzc2V0cycsICdpbWFnZXMnLCAnamF2YXNjcmlwdHMnLCAnc3R5bGVzaGVldHMnXTtcblxuY29uc3QgY2xpZW50Rm9yID0gKG5hbWUpID0+IHtcbiAgbGV0IGhvc3QgPSBzaXRlcy5ob3N0Rm9yKG5hbWUpO1xuICBsZXQgdG9rZW4gPSBzaXRlcy50b2tlbkZvcihuYW1lKTtcbiAgaWYgKGhvc3QgJiYgdG9rZW4pIHtcbiAgICByZXR1cm4gbmV3IFZvb2coaG9zdCwgdG9rZW4pO1xuICB9XG59O1xuXG5jb25zdCBnZXRMYXlvdXRJbmZvID0gKGxheW91dCkgPT4ge1xuICBsZXQgbmFtZSA9IGxheW91dC50aXRsZS5yZXBsYWNlKC9bXlxcd1xcLlxcLV0vZywgJ18nKS50b0xvd2VyQ2FzZSgpO1xuICByZXR1cm4ge1xuICAgIHRpdGxlOiBsYXlvdXQudGl0bGUsXG4gICAgbGF5b3V0X25hbWU6IG5hbWUsXG4gICAgY29udGVudF90eXBlOiBsYXlvdXQuY29udGVudF90eXBlLFxuICAgIGNvbXBvbmVudDogbGF5b3V0LmNvbXBvbmVudCxcbiAgICBmaWxlOiBgJHtsYXlvdXQuY29tcG9uZW50ID8gJ2NvbXBvbmVudHMnIDogJ2xheW91dHMnfS8ke25hbWV9YFxuICB9XG59O1xuXG5jb25zdCBnZXRBc3NldEluZm8gPSAoYXNzZXQpID0+IHtcbiAgcmV0dXJuIHtcbiAgICBraW5kOiBhc3NldC5hc3NldF90eXBlLFxuICAgIGZpbGVuYW1lOiBhc3NldC5maWxlbmFtZSxcbiAgICBmaWxlOiBgJHthc3NldC5hc3NldF90eXBlfXMvJHthc3NldC5maWxlbmFtZX1gLFxuICAgIGNvbnRlbnRfdHlwZTogYXNzZXQuY29udGVudF90eXBlXG4gIH07XG59O1xuXG5jb25zdCBnZXRNYW5pZmVzdCA9IChuYW1lKSA9PiB7XG4gIHJldHVybiBuZXcgUHJvbWlzZSgocmVzb2x2ZSwgcmVqZWN0KSA9PiB7XG4gICAgUHJvbWlzZS5hbGwoW2dldExheW91dHMobmFtZSksIGdldExheW91dEFzc2V0cyhuYW1lKV0pLnRoZW4oZmlsZXMgPT4ge1xuICAgICAgcmVzb2x2ZSh7XG4gICAgICAgIGxheW91dHM6IGZpbGVzWzBdLm1hcChnZXRMYXlvdXRJbmZvKSxcbiAgICAgICAgYXNzZXRzOiBmaWxlc1sxXS5tYXAoZ2V0QXNzZXRJbmZvKVxuICAgICAgfSk7XG4gICAgfSwgcmVqZWN0KTtcbiAgfSk7XG59O1xuXG5jb25zdCB3cml0ZU1hbmlmZXN0ID0gKG5hbWUsIG1hbmlmZXN0KSA9PiB7XG4gIGxldCBtYW5pZmVzdFBhdGggPSBgJHtzaXRlcy5kaXJGb3IobmFtZSl9L21hbmlmZXN0Mi5qc29uYDtcbiAgZmlsZVV0aWxzLndyaXRlRmlsZShtYW5pZmVzdFBhdGgsIEpTT04uc3RyaW5naWZ5KG1hbmlmZXN0LCBudWxsLCAyKSk7XG59O1xuXG5jb25zdCBnZW5lcmF0ZVJlbW90ZU1hbmlmZXN0ID0gKG5hbWUpID0+IHtcbiAgZ2V0TWFuaWZlc3QobmFtZSkudGhlbihfLmN1cnJ5KHdyaXRlTWFuaWZlc3QpKG5hbWUpKTtcbn07XG5cbmNvbnN0IHJlYWRNYW5pZmVzdCA9IChuYW1lKSA9PiB7XG4gIGxldCBtYW5pZmVzdEZpbGVQYXRoID0gcGF0aC5qb2luKHBhdGgubm9ybWFsaXplKHNpdGVzLmRpckZvcihuYW1lKSksICdtYW5pZmVzdDIuanNvbicpO1xuICBpZiAoIWZzLmV4aXN0c1N5bmMobWFuaWZlc3RGaWxlUGF0aCkpIHsgcmV0dXJuOyB9XG5cbiAgdHJ5IHtcbiAgICByZXR1cm4gSlNPTi5wYXJzZShmcy5yZWFkRmlsZVN5bmMobWFuaWZlc3RGaWxlUGF0aCkpO1xuICB9IGNhdGNoIChlKSB7XG4gICAgcmV0dXJuO1xuICB9XG59O1xuXG5jb25zdCBnZXRMYXlvdXRDb250ZW50cyA9IChpZCwgcHJvamVjdE5hbWUpID0+IHtcbiAgcmV0dXJuIG5ldyBQcm9taXNlKChyZXNvbHZlLCByZWplY3QpID0+IHtcbiAgICBjbGllbnRGb3IocHJvamVjdE5hbWUpLmxheW91dChpZCwge30sIChlcnIsIGRhdGEpID0+IHtcbiAgICAgIGlmIChlcnIpIHsgcmVqZWN0KGVycikgfVxuICAgICAgcmVzb2x2ZShkYXRhLmJvZHkpO1xuICAgIH0pO1xuICB9KTtcbn07XG5cbmNvbnN0IGdldExheW91dEFzc2V0Q29udGVudHMgPSAoaWQsIHByb2plY3ROYW1lKSA9PiB7XG4gIHJldHVybiBuZXcgUHJvbWlzZSgocmVzb2x2ZSwgcmVqZWN0KSA9PiB7XG4gICAgY2xpZW50Rm9yKHByb2plY3ROYW1lKS5sYXlvdXRBc3NldChpZCwge30sIChlcnIsIGRhdGEpID0+IHtcbiAgICAgIGlmIChlcnIpIHsgcmVqZWN0KGVycikgfVxuICAgICAgaWYgKGRhdGEuZWRpdGFibGUpIHtcbiAgICAgICAgcmVzb2x2ZShkYXRhLmRhdGEpO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgcmVzb2x2ZShkYXRhLnB1YmxpY191cmwpO1xuICAgICAgfVxuICAgIH0pXG4gIH0pO1xufTtcblxuY29uc3QgZ2V0TGF5b3V0cyA9IChwcm9qZWN0TmFtZSwgb3B0cz17fSkgPT4ge1xuICByZXR1cm4gbmV3IFByb21pc2UoKHJlc29sdmUsIHJlamVjdCkgPT4ge1xuICAgIGNsaWVudEZvcihwcm9qZWN0TmFtZSkubGF5b3V0cyhPYmplY3QuYXNzaWduKHt9LCB7cGVyX3BhZ2U6IDI1MH0sIG9wdHMpLCAoZXJyLCBkYXRhKSA9PiB7XG4gICAgICBpZiAoZXJyKSB7IHJlamVjdChlcnIpIH1cbiAgICAgIHJlc29sdmUoZGF0YSk7XG4gICAgfSk7XG4gIH0pO1xufTtcblxuY29uc3QgZ2V0TGF5b3V0QXNzZXRzID0gKHByb2plY3ROYW1lLCBvcHRzPXt9KSA9PiB7XG4gIHJldHVybiBuZXcgUHJvbWlzZSgocmVzb2x2ZSwgcmVqZWN0KSA9PiB7XG4gICAgY2xpZW50Rm9yKHByb2plY3ROYW1lKS5sYXlvdXRBc3NldHMoT2JqZWN0LmFzc2lnbih7fSwge3Blcl9wYWdlOiAyNTB9LCBvcHRzKSwgKGVyciwgZGF0YSkgPT4ge1xuICAgICAgaWYgKGVycikgeyByZWplY3QoZXJyKSB9XG4gICAgICByZXNvbHZlKGRhdGEpO1xuICAgIH0pO1xuICB9KTtcbn07XG5cbmNvbnN0IHB1bGxBbGxGaWxlcyA9IChwcm9qZWN0TmFtZSkgPT4ge1xuICByZXR1cm4gbmV3IFByb21pc2UoKHJlc29sdmUsIHJlamVjdCkgPT4ge1xuICAgIGxldCBwcm9qZWN0RGlyID0gc2l0ZXMuZGlyRm9yKHByb2plY3ROYW1lKTtcblxuICAgIFByb21pc2UuYWxsKFtcbiAgICAgIGdldExheW91dHMocHJvamVjdE5hbWUpLFxuICAgICAgZ2V0TGF5b3V0QXNzZXRzKHByb2plY3ROYW1lKVxuICAgIF0pLnRoZW4oKFtsYXlvdXRzLCBhc3NldHNdKSA9PiB7XG5cbiAgICAgIFByb21pc2UuYWxsKFtcbiAgICAgICAgbGF5b3V0cy5tYXAobCA9PiB7XG4gICAgICAgICAgbGV0IGZpbGVQYXRoID0gcGF0aC5qb2luKHByb2plY3REaXIsIGAke2wuY29tcG9uZW50ID8gJ2NvbXBvbmVudHMnIDogJ2xheW91dHMnfS8ke25vcm1hbGl6ZVRpdGxlKGwudGl0bGUpfS50cGxgKTtcbiAgICAgICAgICByZXR1cm4gcHVsbEZpbGUocHJvamVjdE5hbWUsIGZpbGVQYXRoKTtcbiAgICAgICAgfSkuY29uY2F0KGFzc2V0cy5tYXAoYSA9PiB7XG4gICAgICAgICAgbGV0IGZpbGVQYXRoID0gcGF0aC5qb2luKHByb2plY3REaXIsIGAke18uaW5jbHVkZXMoWydzdHlsZXNoZWV0JywgJ2ltYWdlJywgJ2phdmFzY3JpcHQnXSwgYS5hc3NldF90eXBlKSA/IGEuYXNzZXRfdHlwZSA6ICdhc3NldCd9cy8ke2EuZmlsZW5hbWV9YCk7XG4gICAgICAgICAgcmV0dXJuIHB1bGxGaWxlKHByb2plY3ROYW1lLCBmaWxlUGF0aCk7XG4gICAgICAgIH0pKVxuICAgICAgXSkudGhlbihyZXNvbHZlKTtcblxuICAgIH0pO1xuICB9KVxufTtcblxuY29uc3QgcHVzaEFsbEZpbGVzID0gKHByb2plY3ROYW1lKSA9PiB7XG4gIHJldHVybiBuZXcgUHJvbWlzZSgocmVzb2x2ZSwgcmVqZWN0KSA9PiB7XG4gICAgbGV0IHByb2plY3REaXIgPSBzaXRlcy5kaXJGb3IocHJvamVjdE5hbWUpO1xuXG4gICAgUHJvbWlzZS5hbGwoW1xuICAgICAgZ2V0TGF5b3V0cyhwcm9qZWN0TmFtZSksXG4gICAgICBnZXRMYXlvdXRBc3NldHMocHJvamVjdE5hbWUpXG4gICAgXSkudGhlbigoW2xheW91dHMsIGFzc2V0c10pID0+IHtcbiAgICAgIFByb21pc2UuYWxsKFtcbiAgICAgICAgbGF5b3V0cy5tYXAobCA9PiB7XG4gICAgICAgICAgbGV0IGZpbGVQYXRoID0gcGF0aC5qb2luKHByb2plY3REaXIsIGAke2wuY29tcG9uZW50ID8gJ2NvbXBvbmVudHMnIDogJ2xheW91dHMnfS8ke25vcm1hbGl6ZVRpdGxlKGwudGl0bGUpfS50cGxgKTtcbiAgICAgICAgICByZXR1cm4gcHVzaEZpbGUocHJvamVjdE5hbWUsIGZpbGVQYXRoKTtcbiAgICAgICAgfSkuY29uY2F0KGFzc2V0cy5maWx0ZXIoYSA9PiBbJ2pzJywgJ2NzcyddLmluZGV4T2YoYS5maWxlbmFtZS5zcGxpdCgnLicpLnJldmVyc2UoKVswXSkgPj0gMCkubWFwKGEgPT4ge1xuICAgICAgICAgIGxldCBmaWxlUGF0aCA9IHBhdGguam9pbihwcm9qZWN0RGlyLCBgJHtfLmluY2x1ZGVzKFsnc3R5bGVzaGVldCcsICdpbWFnZScsICdqYXZhc2NyaXB0J10sIGEuYXNzZXRfdHlwZSkgPyBhLmFzc2V0X3R5cGUgOiAnYXNzZXQnfXMvJHthLmZpbGVuYW1lfWApO1xuICAgICAgICAgIHJldHVybiBwdXNoRmlsZShwcm9qZWN0TmFtZSwgZmlsZVBhdGgpO1xuICAgICAgICB9KSlcbiAgICAgIF0pLnRoZW4ocmVzb2x2ZSk7XG4gICAgfSk7XG4gIH0pO1xufVxuXG5jb25zdCBmaW5kTGF5b3V0T3JDb21wb25lbnQgPSAoZmlsZU5hbWUsIGNvbXBvbmVudCwgcHJvamVjdE5hbWUpID0+IHtcbiAgbGV0IG5hbWUgPSBub3JtYWxpemVUaXRsZShnZXRMYXlvdXROYW1lRnJvbUZpbGVuYW1lKGZpbGVOYW1lKSk7XG4gIHJldHVybiBuZXcgUHJvbWlzZSgocmVzb2x2ZSwgcmVqZWN0KSA9PiB7XG4gICAgcmV0dXJuIGNsaWVudEZvcihwcm9qZWN0TmFtZSkubGF5b3V0cyh7XG4gICAgICBwZXJfcGFnZTogMjUwLFxuICAgICAgJ3EubGF5b3V0LmNvbXBvbmVudCc6IGNvbXBvbmVudCB8fCBmYWxzZVxuICAgIH0sIChlcnIsIGRhdGEpID0+IHtcbiAgICAgIGlmIChlcnIpIHsgcmVqZWN0KGVycikgfVxuICAgICAgbGV0IHJldCA9IGRhdGEuZmlsdGVyKGwgPT4gbm9ybWFsaXplVGl0bGUobC50aXRsZSkgPT0gbmFtZSk7XG4gICAgICBpZiAocmV0Lmxlbmd0aCA9PT0gMCkgeyByZWplY3QodW5kZWZpbmVkKSB9XG4gICAgICByZXNvbHZlKHJldFswXSk7XG4gICAgfSk7XG4gIH0pO1xufVxuXG5jb25zdCBmaW5kTGF5b3V0ID0gKGZpbGVOYW1lLCBwcm9qZWN0TmFtZSkgPT4ge1xuICByZXR1cm4gZmluZExheW91dE9yQ29tcG9uZW50KGZpbGVOYW1lLCBmYWxzZSwgcHJvamVjdE5hbWUpO1xufTtcblxuY29uc3QgZmluZENvbXBvbmVudCA9IChmaWxlTmFtZSwgcHJvamVjdE5hbWUpID0+IHtcbiAgcmV0dXJuIGZpbmRMYXlvdXRPckNvbXBvbmVudChmaWxlTmFtZSwgdHJ1ZSwgcHJvamVjdE5hbWUpO1xufTtcblxuY29uc3QgZmluZExheW91dEFzc2V0ID0gKGZpbGVOYW1lLCBwcm9qZWN0TmFtZSkgPT4ge1xuICByZXR1cm4gbmV3IFByb21pc2UoKHJlc29sdmUsIHJlamVjdCkgPT4ge1xuICAgIHJldHVybiBjbGllbnRGb3IocHJvamVjdE5hbWUpLmxheW91dEFzc2V0cyh7XG4gICAgICBwZXJfcGFnZTogMjUwLFxuICAgICAgJ3EubGF5b3V0X2Fzc2V0LmZpbGVuYW1lJzogZmlsZU5hbWVcbiAgICB9LCAoZXJyLCBkYXRhKSA9PiB7XG4gICAgICBpZiAoZXJyKSB7IHJlamVjdChlcnIpIH1cbiAgICAgIHJlc29sdmUoZGF0YVswXSk7XG4gICAgfSk7XG4gIH0pO1xufTtcblxuY29uc3QgZ2V0RmlsZU5hbWVGcm9tUGF0aCA9IChmaWxlUGF0aCkgPT4ge1xuICByZXR1cm4gZmlsZVBhdGguc3BsaXQoJy8nKVsxXTtcbn07XG5cbmNvbnN0IGdldExheW91dE5hbWVGcm9tRmlsZW5hbWUgPSAoZmlsZU5hbWUpID0+IHtcbiAgcmV0dXJuIGZpbGVOYW1lLnNwbGl0KCcuJylbMF07XG59XG5cbmNvbnN0IGZpbmRGaWxlID0gKGZpbGVQYXRoLCBwcm9qZWN0TmFtZSkgPT4ge1xuICBsZXQgdHlwZSA9IGdldFR5cGVGcm9tUmVsYXRpdmVQYXRoKGZpbGVQYXRoKTtcbiAgaWYgKF8uaW5jbHVkZXMoWydsYXlvdXQnLCAnY29tcG9uZW50J10sIHR5cGUpKSB7XG4gICAgcmV0dXJuIGZpbmRMYXlvdXRPckNvbXBvbmVudChnZXRMYXlvdXROYW1lRnJvbUZpbGVuYW1lKGdldEZpbGVOYW1lRnJvbVBhdGgoZmlsZVBhdGgpKSwgKHR5cGUgPT0gJ2NvbXBvbmVudCcpLCBwcm9qZWN0TmFtZSk7XG4gIH0gZWxzZSB7XG4gICAgcmV0dXJuIGZpbmRMYXlvdXRBc3NldChnZXRGaWxlTmFtZUZyb21QYXRoKGZpbGVQYXRoKSwgcHJvamVjdE5hbWUpO1xuICB9XG59O1xuXG5jb25zdCBub3JtYWxpemVUaXRsZSA9ICh0aXRsZSkgPT4ge1xuICByZXR1cm4gdGl0bGUucmVwbGFjZSgvW15cXHdcXC1cXC5dL2csICdfJykudG9Mb3dlckNhc2UoKTtcbn07XG5cbmNvbnN0IGdldFR5cGVGcm9tUmVsYXRpdmVQYXRoID0gKHBhdGgpID0+IHtcbiAgbGV0IGZvbGRlciA9IHBhdGguc3BsaXQoJy8nKVswXTtcbiAgbGV0IGZvbGRlclRvVHlwZU1hcCA9IHtcbiAgICAnbGF5b3V0cyc6ICdsYXlvdXQnLFxuICAgICdjb21wb25lbnRzJzogJ2NvbXBvbmVudCcsXG4gICAgJ2Fzc2V0cyc6ICdhc3NldCcsXG4gICAgJ2ltYWdlcyc6ICdpbWFnZScsXG4gICAgJ2phdmFzY3JpcHRzJzogJ2phdmFzY3JpcHQnLFxuICAgICdzdHlsZXNoZWV0cyc6ICdzdHlsZXNoZWV0J1xuICB9O1xuXG4gIHJldHVybiBmb2xkZXJUb1R5cGVNYXBbZm9sZGVyXTtcbn07XG5cbmNvbnN0IG5vcm1hbGl6ZVBhdGggPSAocGF0aCwgcHJvamVjdERpcikgPT4ge1xuICByZXR1cm4gcGF0aFxuICAgIC5yZXBsYWNlKHByb2plY3REaXIsICcnKVxuICAgIC5yZXBsYWNlKC9eXFwvLywgJycpO1xufTtcblxuY29uc3Qgd3JpdGVGaWxlID0gKHByb2plY3ROYW1lLCBmaWxlLCBkZXN0UGF0aCkgPT4ge1xuICByZXR1cm4gbmV3IFByb21pc2UoKHJlc29sdmUsIHJlamVjdCkgPT4ge1xuICAgIGlmIChmaWxlKSB7XG4gICAgICBpZiAoXy5pbmNsdWRlcyhPYmplY3Qua2V5cyhmaWxlKSwgJ2xheW91dF9uYW1lJykpIHtcbiAgICAgICAgZ2V0TGF5b3V0Q29udGVudHMoZmlsZS5pZCwgcHJvamVjdE5hbWUpLnRoZW4oY29udGVudHMgPT4ge1xuICAgICAgICAgIHRyeSB7IGZzLm1rZGlyU3luYyhwYXRoLmRpcm5hbWUoZGVzdFBhdGgpKSB9IGNhdGNoKGUpIHsgaWYgKGUuY29kZSAhPSAnRUVYSVNUJykgeyB0aHJvdyBlIH0gfTtcbiAgICAgICAgICBmcy53cml0ZUZpbGUoZGVzdFBhdGgsIGNvbnRlbnRzLCAoZXJyKSA9PiB7XG4gICAgICAgICAgICBpZiAoZXJyKSB7IHJlamVjdChmYWxzZSkgfVxuICAgICAgICAgICAgcmVzb2x2ZSh0cnVlKTtcbiAgICAgICAgICB9KTtcbiAgICAgICAgfSlcbiAgICAgIH0gZWxzZSBpZiAoZmlsZS5lZGl0YWJsZSkge1xuICAgICAgICBnZXRMYXlvdXRBc3NldENvbnRlbnRzKGZpbGUuaWQsIHByb2plY3ROYW1lKS50aGVuKGNvbnRlbnRzID0+IHtcbiAgICAgICAgICB0cnkgeyBmcy5ta2RpclN5bmMocGF0aC5kaXJuYW1lKGRlc3RQYXRoKSkgfSBjYXRjaChlKSB7IGlmIChlLmNvZGUgIT0gJ0VFWElTVCcpIHsgdGhyb3cgZSB9IH07XG4gICAgICAgICAgZnMud3JpdGVGaWxlKGRlc3RQYXRoLCBjb250ZW50cywgKGVycikgPT4ge1xuICAgICAgICAgICAgaWYgKGVycikgeyByZWplY3QoZmFsc2UpIH1cbiAgICAgICAgICAgIHJlc29sdmUodHJ1ZSk7XG4gICAgICAgICAgfSk7XG4gICAgICAgIH0pXG4gICAgICB9IGVsc2Uge1xuICAgICAgICBsZXQgdXJsID0gZmlsZS5wdWJsaWNfdXJsO1xuICAgICAgICB0cnkgeyBmcy5ta2RpclN5bmMocGF0aC5kaXJuYW1lKGRlc3RQYXRoKSkgfSBjYXRjaChlKSB7IGlmIChlLmNvZGUgIT0gJ0VFWElTVCcpIHsgdGhyb3cgZSB9IH07XG4gICAgICAgIGxldCBzdHJlYW0gPSBmcy5jcmVhdGVXcml0ZVN0cmVhbShkZXN0UGF0aCk7XG4gICAgICAgIGlmICh1cmwgJiYgc3RyZWFtKSB7XG4gICAgICAgICAgbGV0IHJlcSA9IHJlcXVlc3QuZ2V0KHVybCkub24oJ2Vycm9yJywgKGVycikgPT4gcmVqZWN0KGZhbHNlKSk7XG4gICAgICAgICAgcmVxLnBpcGUoc3RyZWFtKTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICByZWplY3QoZmFsc2UpO1xuICAgICAgICB9XG4gICAgICB9XG4gICAgfSBlbHNlIHtcbiAgICAgIHJlamVjdCgpO1xuICAgIH1cbiAgfSlcbn07XG5cbmNvbnN0IHVwbG9hZEZpbGUgPSAocHJvamVjdE5hbWUsIGZpbGUsIGZpbGVQYXRoKSA9PiB7XG4gIGxldCBjbGllbnQgPSBjbGllbnRGb3IocHJvamVjdE5hbWUpO1xuICByZXR1cm4gbmV3IFByb21pc2UoKHJlc29sdmUsIHJlamVjdCkgPT4ge1xuICAgIGlmIChmaWxlKSB7XG4gICAgICBpZiAoXy5pbmNsdWRlcyhPYmplY3Qua2V5cyhmaWxlKSwgJ2xheW91dF9uYW1lJykpIHtcbiAgICAgICAgbGV0IGNvbnRlbnRzID0gZnMucmVhZEZpbGVTeW5jKGZpbGVQYXRoLCAndXRmOCcpO1xuICAgICAgICBjbGllbnQudXBkYXRlTGF5b3V0KGZpbGUuaWQsIHtcbiAgICAgICAgICBib2R5OiBjb250ZW50c1xuICAgICAgICB9LCAoZXJyLCBkYXRhKSA9PiB7XG4gICAgICAgICAgIGlmIChlcnIpIHsgcmVqZWN0KGZhbHNlKTsgfSBlbHNlIHsgcmVzb2x2ZSh0cnVlKTsgfVxuICAgICAgICB9KTtcbiAgICAgIH0gZWxzZSBpZiAoZmlsZS5lZGl0YWJsZSkge1xuICAgICAgICBsZXQgY29udGVudHMgPSBmcy5yZWFkRmlsZVN5bmMoZmlsZVBhdGgsICd1dGY4Jyk7XG4gICAgICAgIGNsaWVudC51cGRhdGVMYXlvdXRBc3NldChmaWxlLmlkLCB7XG4gICAgICAgICAgZGF0YTogY29udGVudHNcbiAgICAgICAgfSwgKGVyciwgZGF0YSkgPT4ge1xuICAgICAgICAgICBpZiAoZXJyKSB7IHJlamVjdChmYWxzZSk7IH0gZWxzZSB7IHJlc29sdmUodHJ1ZSk7IH1cbiAgICAgICAgfSk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICByZWplY3QoZmFsc2UpO1xuICAgICAgfVxuICAgIH0gZWxzZSB7XG4gICAgICAgcmVqZWN0KCk7XG4gICAgfVxuICB9KTtcbn07XG5cbmNvbnN0IHB1bGxGaWxlID0gKHByb2plY3ROYW1lLCBmaWxlUGF0aCkgPT4ge1xuICBsZXQgcHJvamVjdERpciA9IHNpdGVzLmRpckZvcihwcm9qZWN0TmFtZSk7XG5cbiAgbGV0IG5vcm1hbGl6ZWRQYXRoID0gbm9ybWFsaXplUGF0aChmaWxlUGF0aCwgcHJvamVjdERpcik7XG5cbiAgcmV0dXJuIG5ldyBQcm9taXNlKChyZXNvbHZlLCByZWplY3QpID0+IHtcbiAgICBmaW5kRmlsZShub3JtYWxpemVkUGF0aCwgcHJvamVjdE5hbWUpLnRoZW4oZmlsZSA9PiB7XG4gICAgICBpZiAoIWZpbGUgfHwgdHlwZW9mIGZpbGUgPT09ICd1bmRlZmluZWQnKSB7XG4gICAgICAgIHJlamVjdCgpO1xuICAgICAgICByZXR1cm47XG4gICAgICB9XG5cbiAgICAgIHJlc29sdmUod3JpdGVGaWxlKHByb2plY3ROYW1lLCBmaWxlLCBmaWxlUGF0aCkpO1xuICAgIH0pXG4gIH0pO1xufVxuXG5jb25zdCBwdXNoRmlsZSA9IChwcm9qZWN0TmFtZSwgZmlsZVBhdGgpID0+IHtcbiAgbGV0IHByb2plY3REaXIgPSBzaXRlcy5kaXJGb3IocHJvamVjdE5hbWUpO1xuICBsZXQgbm9ybWFsaXplZFBhdGggPSBub3JtYWxpemVQYXRoKGZpbGVQYXRoLCBwcm9qZWN0RGlyKTtcblxuICByZXR1cm4gbmV3IFByb21pc2UoKHJlc29sdmUsIHJlamVjdCkgPT4ge1xuICAgIGZpbmRGaWxlKG5vcm1hbGl6ZWRQYXRoLCBwcm9qZWN0TmFtZSkudGhlbihmaWxlID0+IHtcbiAgICAgIGlmICghZmlsZSB8fCB0eXBlb2YgZmlsZSA9PT0gJ3VuZGVmaW5lZCcpIHtcbiAgICAgICAgcmVqZWN0KCk7XG4gICAgICAgIHJldHVybjtcbiAgICAgIH1cbiAgICAgIHJlc29sdmUodXBsb2FkRmlsZShwcm9qZWN0TmFtZSwgZmlsZSwgZmlsZVBhdGgpKTtcbiAgICB9KVxuICB9KTtcbn07XG5cbmNvbnN0IHB1c2hBbGwgPSAocHJvamVjdE5hbWUpID0+IHtcbiAgcmV0dXJuIFsncHVzaCBldmVyeXRoaW5nJ107XG59O1xuXG5jb25zdCBhZGQgPSAocHJvamVjdE5hbWUsIGZpbGVzKSA9PiB7XG4gIHJldHVybiBbJ2FkZCBmaWxlcycsIGZpbGVzXTtcbn07XG5cbmNvbnN0IHJlbW92ZSA9IChwcm9qZWN0TmFtZSwgZmlsZXMpID0+IHtcbiAgcmV0dXJuIFsncmVtb3ZlIGZpbGVzJywgZmlsZXNdO1xufTtcblxuZXhwb3J0IGRlZmF1bHQge1xuICBjbGllbnRGb3IsXG4gIHB1bGxBbGxGaWxlcyxcbiAgcHVzaEFsbEZpbGVzLFxuICBmaW5kTGF5b3V0LFxuICBmaW5kTGF5b3V0QXNzZXQsXG4gIHB1c2hGaWxlLFxuICBwdWxsRmlsZSxcbiAgZ2V0TWFuaWZlc3QsXG4gIHJlYWRNYW5pZmVzdCxcbiAgd3JpdGVNYW5pZmVzdDogZ2VuZXJhdGVSZW1vdGVNYW5pZmVzdFxufTtcblxuIiwie1xuICBcIm5hbWVcIjogXCJraXQtY29yZVwiLFxuICBcInZlcnNpb25cIjogXCIwLjAuMVwiLFxuICBcImRlc2NyaXB0aW9uXCI6IFwiXCIsXG4gIFwibWFpblwiOiBcImluZGV4LmpzXCIsXG4gIFwic2NyaXB0c1wiOiB7XG4gICAgXCJidWlsZFwiOiBcInJvbGx1cCAtbSBpbmxpbmUgLWMgJiYgZWNobyBgZWNobyAkKGRhdGUgK1xcXCJbJUg6JU06JVNdXFxcIikgcmVidWlsdCAuL2luZGV4LmpzYFwiLFxuICAgIFwid2F0Y2hcIjogXCJ3YXRjaCAnbnBtIHJ1biBidWlsZCcgLi9zcmNcIixcbiAgICBcInRlc3RcIjogXCJub2RlIC4vdGVzdC90ZXN0LmpzXCIsXG4gICAgXCJ3YXRjaDp0ZXN0XCI6IFwid2F0Y2ggJ25wbSBydW4gYnVpbGQgJiYgbnBtIHJ1biB0ZXN0JyAuL3NyYyAuL3Rlc3RcIlxuICB9LFxuICBcImF1dGhvclwiOiBcIk1pa2sgUHJpc3RhdmthXCIsXG4gIFwibGljZW5zZVwiOiBcIklTQ1wiLFxuICBcImRlcGVuZGVuY2llc1wiOiB7XG4gICAgXCJibHVlYmlyZFwiOiBcIl4zLjMuMVwiLFxuICAgIFwiaGlnaGxhbmRcIjogXCJeMi43LjFcIixcbiAgICBcImxvZGFzaFwiOiBcIl40LjUuMFwiLFxuICAgIFwibWltZS1kYlwiOiBcIl4xLjIyLjBcIixcbiAgICBcIm1pbWUtdHlwZVwiOiBcIl4zLjAuNFwiLFxuICAgIFwicmVxdWVzdFwiOiBcIl4yLjY5LjBcIixcbiAgICBcInZvb2dcIjogXCJnaXQraHR0cHM6Ly9naXRodWIuY29tL1Zvb2cvdm9vZy5qcy5naXRcIlxuICB9LFxuICBcImRldkRlcGVuZGVuY2llc1wiOiB7XG4gICAgXCJiYWJlbC1jbGlcIjogXCJeNi41LjFcIixcbiAgICBcImJhYmVsLXByZXNldC1lczIwMTUtcm9sbHVwXCI6IFwiXjEuMS4xXCIsXG4gICAgXCJyb2xsdXBcIjogXCJeMC4yNS40XCIsXG4gICAgXCJyb2xsdXAtcGx1Z2luLWJhYmVsXCI6IFwiXjIuMy45XCIsXG4gICAgXCJyb2xsdXAtcGx1Z2luLWpzb25cIjogXCJeMi4wLjBcIixcbiAgICBcIndhdGNoXCI6IFwiXjAuMTcuMVwiXG4gIH1cbn1cbiIsIid1c2Ugc3RyaWN0JztcblxuaW1wb3J0IGZzIGZyb20gJ2ZzJztcbmltcG9ydCBmaWxlVXRpbHMgZnJvbSAnLi9maWxlX3V0aWxzJztcbmltcG9ydCB1dGlscyBmcm9tICcuL3V0aWxzJztcbmltcG9ydCBjb25maWcgZnJvbSAnLi9jb25maWcnO1xuaW1wb3J0IHNpdGVzIGZyb20gJy4vc2l0ZXMnO1xuaW1wb3J0IGFjdGlvbnMgZnJvbSAnLi9hY3Rpb25zJztcbmltcG9ydCB7dmVyc2lvbn0gZnJvbSAnLi4vcGFja2FnZS5qc29uJztcblxuZXhwb3J0IGRlZmF1bHQge1xuICBmaWxlVXRpbHMsXG4gIGNvbmZpZyxcbiAgc2l0ZXMsXG4gIGFjdGlvbnMsXG4gIHV0aWxzLFxuICB2ZXJzaW9uLFxufTtcblxuIl0sIm5hbWVzIjpbIl8iLCJzaXRlcyIsIlByb21pc2UiLCJ3cml0ZUZpbGUiXSwibWFwcGluZ3MiOiI7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7Ozs7OztBQUtBLElBQU0sWUFBWSxTQUFaLFNBQVksQ0FBQyxVQUFELEVBQWdCO1NBQ3pCLEdBQUcsV0FBSCxDQUFlLFVBQWYsRUFBMkIsTUFBM0IsQ0FDTCxVQUFTLElBQVQsRUFBZTtRQUNYLFdBQVcsS0FBSyxJQUFMLENBQVUsVUFBVixFQUFzQixJQUF0QixDQUFYLENBRFc7V0FFUixHQUFHLFFBQUgsQ0FBWSxRQUFaLEVBQXNCLE1BQXRCLEVBQVAsQ0FGZTtHQUFmLENBREYsQ0FEZ0M7Q0FBaEI7O0FBUWxCLElBQU0sY0FBYyxTQUFkLFdBQWMsQ0FBQyxVQUFELEVBQWdCO1NBQzNCLEdBQUcsV0FBSCxDQUFlLFVBQWYsRUFBMkIsTUFBM0IsQ0FBa0MsVUFBUyxJQUFULEVBQWU7UUFDbEQsV0FBVyxLQUFLLElBQUwsQ0FBVSxVQUFWLEVBQXNCLElBQXRCLENBQVgsQ0FEa0Q7V0FFL0MsR0FBRyxRQUFILENBQVksUUFBWixFQUFzQixXQUF0QixFQUFQLENBRnNEO0dBQWYsQ0FBekMsQ0FEa0M7Q0FBaEI7O0FBT3BCLElBQU0sa0JBQWtCLFNBQWxCLGVBQWtCLENBQUMsUUFBRCxFQUFXLE9BQVgsRUFBdUI7U0FDdEMsR0FBRyxZQUFILENBQWdCLFFBQWhCLEVBQTBCLE9BQTFCLENBQVAsQ0FENkM7Q0FBdkI7O0FBSXhCLElBQU0sYUFBYSxTQUFiLFVBQWEsQ0FBQyxRQUFELEVBQWM7U0FDeEIsQ0FBQyxlQUFELEVBQWtCLFFBQWxCLENBQVAsQ0FEK0I7Q0FBZDs7QUFJbkIsSUFBTSxZQUFZLFNBQVosU0FBWSxDQUFDLFFBQUQsRUFBVyxJ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