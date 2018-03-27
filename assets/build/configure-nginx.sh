#/bin/bash

set -ex

# override default nginx config
cat << EOF >/etc/nginx/nginx.conf
worker_processes 1;
error_log /var/log/gitlab/nginx/error.log;
pid /tmp/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024;
}
EOF