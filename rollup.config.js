import json from 'rollup-plugin-json';
import babel from 'rollup-plugin-babel';

export default {
  entry: 'src/core.js',
  format: 'cjs',
  plugins: [
    json(),
    babel({
      exclude: 'node_modules/**'
    })
  ],
  dest: 'index.js'
};
