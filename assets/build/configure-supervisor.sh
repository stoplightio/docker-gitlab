#!/bin/bash
set -ex

mkdir -p ${GITLAB_HOME}/tmp/supervisord && chown -R ${GITLAB_USER}: ${GITLAB_HOME}/tmp
mkdir -p ${SUPERVISOR_CONF_DIR} && chown -R ${GITLAB_USER}: ${SUPERVISOR_CONF_DIR}

echo ${SUPERVISOR_CONF}
cat > ${SUPERVISOR_CONF} <<EOF
[unix_http_server]
file=${GITLAB_INSTALL_DIR}/tmp/sockets/supervisor.sock

[supervisord]
logfile=/dev/stdout
logfile_maxbytes=0MB
logfile_backups=10
loglevel=info
pidfile=${GITLAB_INSTALL_DIR}/tmp/pids/supervisord.pid
nodaemon=true
minfds=1024
minprocs=200

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=http://127.0.0.1:9001 ; use an http:// url to specify an inet socket

[include]
files = supervisord.d/*.conf
EOF

# update supervisor config
# sed -i 's/supervisord.d\/\*.ini/supervisord.d\/\*.conf/' ${SUPERVISOR_CONF}
# sed -i 's/serverurl=unix.*/;serverurl=unix/' ${SUPERVISOR_CONF}
# sed -i 's/\;serverurl=http:\/\/127.0.0.1:9001/serverurl=http:\/\/127.0.0.1:9001/' ${SUPERVISOR_CONF}
# sed -i 's/logfile=.\*/logfile=\/dev\/stdout/' ${SUPERVISOR_CONF}
# sed -i 's/logfile_maxbytes=.\*/logfile_maxbytes=0/' ${SUPERVISOR_CONF}

# configure supervisord to start unicorn
cat > ${SUPERVISOR_CONF_DIR}/unicorn.conf <<EOF
[program:unicorn]
priority=10
directory=${GITLAB_INSTALL_DIR}
environment=HOME=${GITLAB_HOME}
command=bundle exec unicorn_rails -c ${GITLAB_INSTALL_DIR}/config/unicorn.rb -E ${RAILS_ENV}
user=git
autostart=true
autorestart=true
stopsignal=QUIT
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile_maxbytes=0
EOF

# configure supervisord to start sidekiq
cat > ${SUPERVISOR_CONF_DIR}/sidekiq.conf <<EOF
[program:sidekiq]
priority=10
directory=${GITLAB_INSTALL_DIR}
environment=HOME=${GITLAB_HOME}
command=bundle exec sidekiq -c {{SIDEKIQ_CONCURRENCY}}
  -C ${GITLAB_INSTALL_DIR}/config/sidekiq_queues.yml
  -e ${RAILS_ENV}
  -t {{SIDEKIQ_SHUTDOWN_TIMEOUT}}
  -P ${GITLAB_INSTALL_DIR}/tmp/pids/sidekiq.pid
user=git
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile_maxbytes=0
EOF

# configure supervisord to start gitlab-workhorse
cat > ${SUPERVISOR_CONF_DIR}/gitlab-workhorse.conf <<EOF
[program:gitlab-workhorse]
priority=20
directory=${GITLAB_INSTALL_DIR}
environment=HOME=${GITLAB_HOME}
command=/usr/local/bin/gitlab-workhorse
  -listenUmask 0
  -listenNetwork tcp
  -listenAddr ":8181"
  -authBackend http://127.0.0.1:9000{{GITLAB_RELATIVE_URL_ROOT}}
  -authSocket ${GITLAB_INSTALL_DIR}/tmp/sockets/gitlab.socket
  -documentRoot ${GITLAB_INSTALL_DIR}/public
  -proxyHeadersTimeout {{GITLAB_WORKHORSE_TIMEOUT}}
user=git
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile_maxbytes=0
EOF

# configure supervisord to start gitaly
cat > ${SUPERVISOR_CONF_DIR}/gitaly.conf <<EOF
[program:gitaly]
priority=5
directory=${GITLAB_GITALY_INSTALL_DIR}
environment=HOME=${GITLAB_HOME}
command=/usr/local/bin/gitaly ${GITLAB_GITALY_INSTALL_DIR}/config.toml
user=git
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile_maxbytes=0
EOF

# configure supervisord to start nginx
cat > ${SUPERVISOR_CONF_DIR}/nginx.conf <<EOF
[program:nginx]
priority=20
directory=${NGINX_DIR}
command=/usr/sbin/nginx -p ${NGINX_DIR} -g "daemon off;" -c nginx.conf
user=git
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stderr_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile_maxbytes=0
EOF

# # configure supervisord to start crond
# cat > /etc/supervisor/conf.d/cron.conf <<EOF
# [program:cron]
# priority=20
# directory=/tmp
# command=/usr/sbin/cron -f
# user=root
# stdout_logfile=/dev/stdout
# stderr_logfile=/dev/stdout
# stdout_logfile_maxbytes=0
# stderr_logfile_maxbytes=0
# EOF