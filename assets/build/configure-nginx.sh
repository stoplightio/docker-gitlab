#/bin/bash

set -ex

test -d ${NGINX_DIR} || mkdir -p ${NGINX_DIR}
test -d ${NGINX_CONF_DIR} || mkdir -p ${NGINX_CONF_DIR}

# override default nginx config
cat << EOF > ${NGINX_CONF}
worker_processes 1;
error_log /dev/stderr;
pid /tmp/nginx.pid;

# server_names_hash_bucket_size 64;

include /usr/share/nginx/modules/*.conf;
include conf.d/*.conf;

events {
    worker_connections 1024;
}
EOF