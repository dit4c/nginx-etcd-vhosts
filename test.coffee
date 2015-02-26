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
  json = JSON.stringify

  it 'is a function', () ->
    expect(kvp).to.be.a('function')

  it 'should produce null with bad value data', () ->
    expect(kvp('foo', 'bar')).to.be.null
    expect(kvp('foo', '[]')).to.be.null

  it 'should produce template data', () ->
    json = JSON.stringify
    result = kvp 'frontend:example.test',
      json(["example", "http://bar:9000", "http://baz:9001"])
    expect(result).not.to.be.null
    expect(result.domain).to.equal('example.test')
    expect(result.domain_underscored).to.equal('example_test')
    expect(result.name).to.equal('example')
    expect(result.protocol).to.equal('http')
    expect(result.servers).to.deep.equal(["bar:9000", "baz:9001"])

  it 'should handle mixed backends', () ->
    result = kvp 'frontend:example.test',
      json(["example", "http://bar:9000", "https://baz:9001"])
    expect(result).not.to.be.null
    expect(result.domain).to.equal('example.test')
    expect(result.domain_underscored).to.equal('example_test')
    expect(result.name).to.equal('example')
    expect(result.protocol).to.equal('https')
    expect(result.servers).to.deep.equal(['baz:9001'])
