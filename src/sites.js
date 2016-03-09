'use strict';

import config from './config';
import fileUtils from './file_utils';
import path from 'path';
import _ from 'lodash';
import fs from 'fs';
import mime from 'mime-type/with-db';

mime.define('application/vnd.voog.design.custom+liquid', {extensions: ['tpl']}, mime.dupOverwrite);

// byName :: string -> object?
const byName = (name) => {
  return config.sites().filter(site => {
    return site.name === name || site.host === name;
  })[0];
};

// add :: object -> bool
const add = (data) => {
  if (_.has(data, 'host') && _.has(data, 'token')) {
    let sites = config.sites();
    sites.push(data);
    config.write('sites', sites);
    return true;
  } else {
    return false;
  };
};

// remove :: string -> bool
const remove = (name) => {
  let sitesInConfig = config.sites();
  let siteNames = sitesInConfig.map(site => site.name || site.host);
  let idx = siteNames.indexOf(name);
  if (idx < 0) { return false; }
  let finalSites = sitesInConfig.slice(0, idx).concat(sitesInConfig.slice(idx + 1));
  return config.write('sites', finalSites);
};

const getFileInfo = (filePath) => {
  let stat = fs.statSync(filePath);
  let fileName = path.basename(filePath);
  return {
    file: fileName,
    size: stat.size,
    contentType: mime.lookup(fileName),
    path: filePath,
    updatedAt: stat.mtime
  };
};

// filesFor :: string -> object?
const filesFor = (name) => {
  let folders = [
    'assets', 'components', 'images', 'javascripts', 'layouts', 'stylesheets'
  ];

  let workingDir = dirFor(name);

  let root = fileUtils.listFolders(workingDir);

  if (root) {
    return folders.reduce(function(structure, folder) {
      if (root.indexOf(folder) >= 0) {
        let folderPath = path.join(workingDir, folder);
        structure[folder] = fileUtils.listFiles(folderPath).filter(function(file) {
          let fullPath = path.join(folderPath, file);
          let stat = fs.statSync(fullPath);

          return stat.isFile();
        }).map(function(file) {
          let fullPath = path.join(folderPath, file);

          return getFileInfo(fullPath);
        });
      }
      return structure;
    }, {});
  }
};

// dirFor :: string -> string?
const dirFor = (name) => {
  let site = byName(name);
  if (site) {
    return site.dir || site.path;
  }
};

// hostFor :: string -> string?
const hostFor = (name) => {
  let site = byName(name);
  if (site) {
    return site.host;
  }
};

// tokenFor :: string -> string?
const tokenFor = (name) => {
  let site = byName(name);
  if (site) {
    return site.token || site.api_token;
  }
};

// names :: * -> [string]
const names = () => {
  return config.sites().map(function(site) {
    return site.name || site.host;
  });
};

export default {
  byName,
  add,
  remove,
  filesFor,
  dirFor,
  hostFor,
  tokenFor,
  names
};

