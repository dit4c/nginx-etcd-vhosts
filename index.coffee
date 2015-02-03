'use strict';

env = process.env
async = require('async')
child_process = require('child_process')
fs = require('fs')
path = require('path')
url = require('url')
etcdjs = require('etcdjs')
liveCollection = require('etcd-live-collection')
_ = require("lodash")
Hogan = require('hogan.js')

isFrontend = (key) ->
  _.startsWith(key.split('/').pop(), "frontend:")

asTemplateData = (key, value) ->
  domain = key.split('/').pop().split(':').pop()
  data = JSON.parse(value)
  name = data.shift()
  backends = _.groupBy(
    url.parse(s) for s in data, (u) -> _.trimRight(u.protocol,':'))
  protocol = if backends['https'] then 'https' else 'http'
  {
    "domain": domain,
    "domain_underscored": domain.replace(/\./g,'_'),
    "name": name,
    "protocol": protocol,
    "servers": (u.host for u in backends[protocol])
  }

# Write file, but only if contents differs. Return true if changed, false if not
writeIfDifferent = (filepath, content, callback) ->
  fs.readFile filepath, "utf-8", (err, data) ->
    if data == content
      callback(null, false)
    else
      console.log("Updating: "+filepath)
      fs.writeFile filepath, content, (err) ->
        if err
          callback(err)
        else
          callback(null, true)

# Generate files, returning true if file was changed
generateFile = (outputDir, vhost, template, callback) ->
  filename = vhost.domain_underscored + ".conf"
  filepath = path.join(outputDir, filename)
  rendered = template.render(vhost)
  writeIfDifferent filepath, rendered, (err, changed) ->
    if err
      callback(err)
    else
      callback null,
        file: filename
        changed: changed

# Generate files, returning true if reload is required
generateFiles = (outputDir, vhosts, template, callback) ->
  f = (vhost, cb) ->
    generateFile(outputDir, vhost, template, cb)
  async.mapLimit vhosts, 5, f, (err, results) ->
    if (err)
      callback(err)
    else
      callback null,
        files: _.pluck(results, 'file')
        changed: _.any(results, (r) -> r.changed)

removeOldFiles = (outputDir, filesToKeep, callback) ->
  deleteFile = (filename, callback) ->
    filepath = path.join(outputDir, filename)
    console.log("Deleting: "+filepath)
    fs.unlink filepath, callback
  fs.readdir outputDir, (err, files) ->
    filesToRemove = _.difference(files, filesToKeep)
    async.eachSeries filesToRemove, deleteFile, callback

module.exports = (options) ->
  template = Hogan.compile(options.template)
  etcd = etcdjs(options.etcd.servers)
  collection = liveCollection(etcd, options.etcd.path)

  reloadConfig = (callback) ->
    console.log("Reloading nginx: "+options.cmd)
    child_process.exec options.cmd, (error, stdout, stderr) ->
      callback()

  updateConfig = () ->
    generateFiles(
      options.dir,
      asTemplateData(k,v) for k, v of collection.values() when isFrontend(k),
      template,
      (err, result) ->
        if err
          console.log(err)
        else
          removeOldFiles options.dir, result.files, (err) ->
            if err
              console.log(err)
            else if result.changed
              # Intentionally not reloading if all we did was delete files, as
              # this could cause unpleasant consequences if the collection is
              # falsely empty.
              reloadConfig(() -> )
    )

  collection.on(event, updateConfig) for event in ['ready', 'action']
