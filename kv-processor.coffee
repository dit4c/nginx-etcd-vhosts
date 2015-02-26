'use strict'

_ = require("lodash")
url = require('url')

asTemplateData = (domain, data) ->
  name = data.shift()
  backends = _.groupBy(
    url.parse(s) for s in data, (u) -> _.trimRight(u.protocol,':'))
  protocol = if backends['https'] then 'https' else 'http'
  if (backends[protocol] || []).length == 0
    null
  else
    "domain": domain
    "domain_underscored": domain.replace(/\./g,'_')
    "name": name
    "protocol": protocol
    "servers": (u.host for u in backends[protocol])

module.exports = (k, vStr) ->
  domain = k.split('/').pop().split(':').pop()
  data =
    try
      JSON.parse(vStr)
    catch e
      null
  if typeof(domain) == "string" && data instanceof Array
    asTemplateData(domain, data)
  else
    null
