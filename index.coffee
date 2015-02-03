'use strict';

env = process.env
crypto = require('crypto')
url = require('url')
etcdjs = require('etcdjs')
liveCollection = require('etcd-live-collection')
_ = require("lodash")

etcdPeers = (env.ETCDCTL_PEERS || "127.0.0.1:2379").split(',')
etcdPath = env.HIPACHE_PATH || "/"

etcd = etcdjs(etcdPeers)
collection = liveCollection(etcd, etcdPath)

loggerFor = (name) ->
  (msg) -> console.log("["+name+"] "+msg)

isFrontend = (key) ->
  _.startsWith(key.split('/').pop(), "frontend:")

sha256 = (s) ->
  crypto.createHash('sha256').update(s).digest('hex')

asTemplateData = (key, value) ->
  domain = key.split('/').pop().split(':').pop()
  data = JSON.parse(value)
  name = data.shift()
  backends = _.groupBy(
    url.parse(s) for s in data, (u) -> _.trimRight(u.protocol,':'))
  protocol = if backends['https'] then 'https' else 'http'
  {
    "domain": domain,
    "domain_hashed": sha256(domain),
    "name": name,
    "protocol": protocol,
    "servers": (u.host for u in backends[protocol])
  }

updateConfig = () ->
  hosts = asTemplateData(k,v) for k, v of collection.values() when isFrontend(k)
  console.log("Entries: ", hosts)

collection.on(event, updateConfig) for event in ['ready', 'action']
