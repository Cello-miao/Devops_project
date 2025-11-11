// simple smoke test for CI
const pkg = require('../package.json')

console.log('Running basic project smoke tests...')
if (!pkg || !pkg.name) {
  console.error('package.json missing name')
  process.exit(1)
}
console.log(`Project name: ${pkg.name}`)
console.log('Node version:', process.version)
console.log('Test passed')
process.exit(0)
