'use strict';

import fs from 'fs';
import path from 'path';

const listFiles = (folderPath) => {
  return fs.readdirSync(folderPath).filter(
    function(item) {
    var itemPath = path.join(folderPath, item);
    return fs.statSync(itemPath).isFile();
  });
};

const listFolders = (folderPath) => {
  return fs.readdirSync(folderPath).filter(function(item) {
    var itemPath = path.join(folderPath, item);
    return fs.statSync(itemPath).isDirectory();
  });
};

const getFileContents = (filePath, options) => {
  return fs.readFileSync(filePath, options);
};

const deleteFile = (filePath) => {
  return ['fs.unlinkSync', filePath];
};

const writeFile = (filePath, data) => {
  return fs.writeFileSync(filePath, data);
};

export default {
  listFiles,
  listFolders,
  deleteFile,
  writeFile,
  cwd: process.cwd,
  getFileContents
};
