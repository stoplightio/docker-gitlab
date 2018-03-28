#/bin/bash

set -ex

test -d ${NGINX_DIR} || mkdir -p ${NGINX_DIR}
test -d ${NGINX_CONF_DIR} || mkdir -p ${NGINX_CONF_DIR}

# override default nginx config
cat << EOF > ${NGINX_CONF}
worker_processes 1;
error_log /dev/stderr;
pid /tmp/nginx.pid;

include /usr/share/nginx/modules/*.conf;
include conf.d/*.conf;

events {
    worker_connections 1024;
}

http {
  client_body_temp_path /tmp/client_body;
  fastcgi_temp_path /tmp/fastcgi_temp;
  proxy_temp_path /tmp/proxy_temp;
  scgi_temp_path /tmp/scgi_temp;
  uwsgi_temp_path /tmp/uwsgi_temp;
 
  tcp_nopush on;
  tcp_nodelay on;
  keepalive_timeout 65;
  types_hash_max_size 2048;
 
  include /etc/nginx/mime.types;
  index index.html index.htm index.php;
 
  log_format   main '$remote_addr - $remote_user [$time_local] $status '
    '"$request" $body_bytes_sent "$http_referer" '
    '"$http_user_agent" "$http_x_forwarded_for"';
 
  default_type application/octet-stream;
 
  server {
    listen 3000;
    listen [::]:3000 default ipv6only=on;
 
    root /usr/share/nginx/html;

    access_log /dev/stdout;
    error_log /dev/stderr;
 
    location / {
      # First attempt to serve request as file, then as directory, then fall
      # back to index.html.
      try_files $uri $uri/ /index.html;
    }
  }
}
EOF