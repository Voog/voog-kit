'use strict';

import config from './config';
import sites from './sites';
import Voog from 'voog';
import fileUtils from './file_utils';
import _ from 'lodash';
import {Promise} from 'bluebird';

const clientFor = (name) => {
  let host = sites.hostFor(name);
  let token = sites.tokenFor(name);

  if (host && token) {
    return new Voog(host, token);
  }
};

const getLayouts = (name) => {
  return new Promise(function(resolve, reject) {
    clientFor(name).layouts({}, function(err, data) {
      if (err) { reject(err); }
      resolve(data);
    });
  });
};

const getLayoutAssets = (name) => {
  return new Promise(function(resolve, reject) {
    clientFor(name).layoutAssets({}, function(err, data) {
      if (err) { reject(err); }
      resolve(data);
    });
  });
};

const getFiles = (name) => {
  return new Promise(function(resolve, reject) {
    Promise.all([getLayouts(name), getLayoutAssets(name)]).then(function(layouts, assets) {
      resolve(layouts, assets);
    }, function(err) {
      reject(err);
    });
  });
};

const pull = (paths) => {

};

const pullAll = () => {

};

const push = (files, options) => {

};

const pushAll = () => {

};

const add = (files) => {

};

const remove = (files) => {

};

export default {
  clientFor,
  getLayouts,
  getLayoutAssets,
  getFiles,
  push
};

