'use strict';

var config = require('./config');
var fileUtils = require('./file_utils');

function byName() {

}

function add() {

}

function remove() {

}

function structureFor() {

}

function pathFor() {

}

function names() {

}

module.exports = {
  byName: byName,
  add: add,
  remove: remove,
  structureFor: structureFor,
  pathFor: pathFor,
  names: names
};
// -----------------------------------

/*

byName :: string -> object
byName(name)

add :: object -> bool
add(data)

remove :: string -> bool
remove(name)

structureFor :: string -> object
structureFor(site_name)

pathFor :: string -> string
pathFor(site_name)

names :: * -> [string]
names()


var site = Kit.sites.byName(name);

var files = site.getStructure();

var stylesheets = files.stylesheets;

stylesheets[0] = {
  kind: 'stylesheet',
  filename: 'main.min.css',
  content_type: 'text/css',
  size: 12405
};


var apiClient = new Voog(site.host, site.token);

Kit.actions.push(site, apiClient, [files])

Kit.actions.pull(site, apiClient, [files])
*/
