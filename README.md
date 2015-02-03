# nginx-etcd-vhosts

Hipache is great, but compared to Nginx is can be quite resource intensive. This package is designed as a drop-in replacement for using Hipache with the etcd backend. It's intended to be similar to dotCloud's [Version 1](http://blog.dotcloud.com/under-the-hood-dotcloud-http-routing-layer) solution.

It works by monitoring etcd for changes, and outputing virtual host configurations for each of the defined frontends.

Nginx has supported websockets for some time now, so unlike in the dotCloud experience, you only have to worry about config regeneration overheads. If you have a rate of change for your domain entries, you may prefer a solution based on Nginx + Lua with [hipache-nginx](https://github.com/samalba/hipache-nginx) or [OpenResty](http://openresty.org/#DynamicRoutingBasedOnRedis).

## Limitations

 * Cannot handle different protocols for backends of a single frontend. eg. `["foo", "http://bar:9000", "https://baz:9001"]`
 * Running user must be able to reload nginx

## Template Data

The Hipache key-value pair is converted into JSON suitable for Nginx templates.

For instance, `frontend:my.example.com` with a value of:

```json
["example", "http://bar:9000", "http://baz:9001"]
```

is converted to:

```json
{
  "domain": "my.example.com",
  "domain_hashed": "e1389c9a53847d15700daf57515e5fc3e023644ad95345c09b32ef9d757b45d6",
  "name": "example",
  "protocol": "http",
  "servers": ["bar:9000", "baz:9000"]
}
```

## Template

Here's an example template:

```nginx
upstream vhost_backend_{{domain_hashed}} {
  {{#servers}}
  server {{.}};
  {{/servers}}
}

server {
  listen  [::]:443 ssl spdy ipv6only=off;
  server_name  {{domain}};

  location / {
    proxy_set_header "X-Server-Name" "{{name}}"
    proxy_pass {{protocol}}://vhost_backend_{{domain_hashed}};
  }
}
```
