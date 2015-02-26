'use strict'

expect = require('chai').expect
gutil = require('gulp-util')
mocha = require('./')

out = process.stdout.write.bind(process.stdout)
err = process.stderr.write.bind(process.stderr)

afterEach () ->
  process.stdout.write = out
  process.stderr.write = err

describe 'kv-processor', () ->
  kvp = require('./kv-processor')

  it 'is a function', () ->
    expect(kvp).to.be.a('function')

  it 'should produce null with bad value data', () ->
    expect(kvp('foo', 'bar')).to.be.null
    expect(kvp('foo', '[]')).to.be.null

  it 'should produce template data', () ->
    json = JSON.stringify
    r1 = kvp 'frontend:example.test',
      json(["example", "http://bar:9000", "http://baz:9001"])
    expect(r1).not.to.be.null
    expect(r1.domain).to.equal('example.test')
    expect(r1.domain_underscored).to.equal('example_test')
    expect(r1.name).to.equal('example')
    expect(r1.protocol).to.equal('http')
    expect(r1.servers).to.deep.equal(["bar:9000", "baz:9001"])
