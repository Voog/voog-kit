var Kit = require('..');
var assert = require('assert');

const validFiles = [
  //'/Users/mikk/dev/test/stylesheets/main.css',
  //'/Users/mikk/dev/test/stylesheets/main.min.css',
  //'/Users/mikk/dev/test/layouts/common_page.tpl',
  //'/Users/mikk/dev/test/images/ico-flags.png'
];

const invalidFiles = [
  //'/Users/mikk/dev/test/stylesheets/invalid.css',
  //'/Users/mikk/dev/test/invalid/invalid.tpl'
];

validFiles.forEach(file => {
  Kit.actions.pushFile('test', file).then(validFile => {
    console.log('pushing', file);
    assert(validFile, 'test?');
  })
});

invalidFiles.forEach(file => {
  Kit.actions.pullFile('test', file).then(null, err => {
    assert(typeof err === 'undefined', 'pulling invalid files should return undefined')
  })
});


//Kit.actions.pullAllFiles('test').then(promises => {promises.map((console.log))});
Kit.actions.pushAllFiles('test').then(console.log);

//Kit.actions.findComponent('template-tools', 'test').then(file => {
  //console.log('testing findComponent with valid inputs');
  //assert(file, 'there should be a return value');
  //assert(typeof file === 'object', 'return value should be an object')
  //console.log('ok!')
//});

//Kit.actions.findComponent('null', 'test').then(file => {
  //console.log('testing findComponent with invalid inputs');
  //assert(typeof file === 'undefined', 'the return value should be undefined');
  //console.log('ok!')
//});

//Kit.actions.findLayoutAsset('main.css', 'test').then(file => {
  //console.log('testing findLayoutAsset with valid inputs');
  //assert(file, 'these should be a return value');
  //assert(typeof file === 'object', 'return value should be an object')
  //console.log('ok!')
//});

//Kit.actions.findLayoutAsset('null.css', 'test').then(file => {
  //console.log('testing findLayoutAsset with invalid inputs');
  //assert(typeof file === 'undefined', 'the return value should be undefined');
  //console.log('ok!')
//});

