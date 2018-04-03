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
 
  index index.html index.htm index.php;
 
  log_format main '\$remote_addr - \$remote_user [\$time_local] \$status '
    '\"$request" \$body_bytes_sent "\$http_referer" '
    '"\$http_user_agent" "\$http_x_forwarded_for"';
 
  default_type application/octet-stream;

  include ${NGINX_CONF_DIR}/*;
}
EOF