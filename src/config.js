'use strict';

import fs from 'fs';
import path from 'path';

const CONFIG_FILENAME = '.voog';

const HOMEDIR = process.env.HOME;
const LOCALDIR = process.cwd();

const LOCAL_CONFIG = path.join(LOCALDIR, CONFIG_FILENAME);
const GLOBAL_CONFIG = path.join(HOMEDIR, CONFIG_FILENAME);

const siteByName = (name, options) => {
  return sites().filter(function(p) {
    return p.name === name;
  })[0];
};

const sites = (options) => {
  return read('sites', options) || [];
};

const write = (key, value, options) => {
  let path;
  if (!options || (_.has(options, 'global') && options.global === true)) {
    path = GLOBAL_CONFIG;
  } else {
    path = LOCAL_CONFIG;
  }
  let config = read(null, options) || {};
  config[key] = value;

  let fileContents = JSON.stringify(config, null, 2);

  fs.writeFileSync(path, fileContents);
  return true;
};

const read = (key, options) => {
  let path;
  if (!options || (_.has(options, 'global') && options.global === true)) {
    path = GLOBAL_CONFIG;
  } else {
    path = LOCAL_CONFIG;
  }

  try {
    let data = fs.readFileSync(path, 'utf8');
    let parsedData = JSON.parse(data);
    if (typeof key === 'string') {
      return parsedData[key];
    } else {
      return parsedData;
    }
  } catch (e) {
    return;
  }
};

const deleteKey = (key, options) => {
  if (!options) {
    let path = GLOBAL_CONFIG;
  } else if (options.hasOwnProperty('global') && options.global === true) {
    let path = GLOBAL_CONFIG;
  } else {
    let path = LOCAL_CONFIG;
  }

  let config = read(null, options);
  let deleted = delete config[key];

  if (deleted) {
    let fileContents = JSON.stringify(config);
    fs.writeFileSync(path, fileContents);
  }

  return deleted;
};

const isPresent = (global) => {
  if (global) {
    let path = GLOBAL_CONFIG;
  } else {
    let path = LOCAL_CONFIG;
  }
  return fs.existsSync(path);
};

const hasKey = (key, options) => {
  let config = read(null, options);
  return (typeof config !== 'undefined') && config.hasOwnProperty(key);
};

export default {
  siteByName,
  write,
  read,
  delete: deleteKey,
  isPresent,
  hasKey,
  sites
};

