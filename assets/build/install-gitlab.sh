#!/bin/bash
set -ex

GITLAB_CLONE_URL=https://github.com/stoplightio/gitlabhq.git
GITLAB_SHELL_URL=https://gitlab.com/gitlab-org/gitlab-shell/repository/archive.tar.gz
GITLAB_WORKHORSE_URL=https://gitlab.com/gitlab-org/gitlab-workhorse.git
GITLAB_PAGES_URL=https://gitlab.com/gitlab-org/gitlab-pages.git
GITLAB_GITALY_URL=https://gitlab.com/gitlab-org/gitaly.git

# set PATH (fixes cron job PATH issues)
cat >> ${GITLAB_HOME}/.profile <<EOF
PATH=/usr/local/sbin:/usr/local/bin:\$PATH
EOF

git config --global core.autocrlf input
git config --global gc.auto 0
git config --global repack.writeBitmaps true

rm -rf ${GITLAB_HOME}/repositories

# remove HSTS config from the default headers, we configure it in nginx
sed -i "/headers\['Strict-Transport-Security'\]/d" ${GITLAB_INSTALL_DIR}/app/controllers/application_controller.rb

# revert `rake gitlab:setup` changes from gitlabhq/gitlabhq@a54af831bae023770bf9b2633cc45ec0d5f5a66a
sed -i 's/db:reset/db:setup/' ${GITLAB_INSTALL_DIR}/lib/tasks/gitlab/setup.rake

cd ${GITLAB_INSTALL_DIR}

cp ${GITLAB_INSTALL_DIR}/config/resque.yml.example ${GITLAB_INSTALL_DIR}/config/resque.yml
cp ${GITLAB_INSTALL_DIR}/config/gitlab.yml.example ${GITLAB_INSTALL_DIR}/config/gitlab.yml
cp ${GITLAB_INSTALL_DIR}/config/database.yml.mysql ${GITLAB_INSTALL_DIR}/config/database.yml

# remove auto generated ${GITLAB_DATA_DIR}/config/secrets.yml
rm -rf ${GITLAB_DATA_DIR}/config/secrets.yml

# remove gitlab shell and workhorse secrets
rm -f ${GITLAB_INSTALL_DIR}/.gitlab_shell_secret ${GITLAB_INSTALL_DIR}/.gitlab_workhorse_secret

mkdir -p ${GITLAB_INSTALL_DIR}/tmp/pids/ ${GITLAB_INSTALL_DIR}/tmp/sockets/

# symlink ${GITLAB_HOME}/.ssh -> ${GITLAB_LOG_DIR}/gitlab
rm -rf ${GITLAB_HOME}/.ssh
ln -sf ${GITLAB_DATA_DIR}/.ssh ${GITLAB_HOME}/.ssh

# symlink ${GITLAB_INSTALL_DIR}/public/uploads -> ${GITLAB_DATA_DIR}/uploads
rm -rf ${GITLAB_INSTALL_DIR}/public/uploads
ln -sf ${GITLAB_DATA_DIR}/uploads ${GITLAB_INSTALL_DIR}/public/uploads

# symlink ${GITLAB_INSTALL_DIR}/.secret -> ${GITLAB_DATA_DIR}/.secret
rm -rf ${GITLAB_INSTALL_DIR}/.secret
ln -sf ${GITLAB_DATA_DIR}/.secret ${GITLAB_INSTALL_DIR}/.secret

# WORKAROUND for https://github.com/sameersbn/docker-gitlab/issues/509
rm -rf ${GITLAB_INSTALL_DIR}/builds
rm -rf ${GITLAB_INSTALL_DIR}/shared

# install gitlab bootscript, to silence gitlab:check warnings
cp ${GITLAB_INSTALL_DIR}/lib/support/init.d/gitlab /etc/init.d/gitlab

# configure supervisord log rotation
# cat > /etc/logrotate.d/supervisord <<EOF
# ${GITLAB_LOG_DIR}/supervisor/*.log {
#   weekly
#   missingok
#   rotate 52
#   compress
#   delaycompress
#   notifempty
#   copytruncate
# }
# EOF

# configure gitlab log rotation
# cat > /etc/logrotate.d/gitlab <<EOF
# ${GITLAB_LOG_DIR}/gitlab/*.log {
#   weekly
#   missingok
#   rotate 52
#   compress
#   delaycompress
#   notifempty
#   copytruncate
# }
# EOF

# configure gitlab-shell log rotation
# cat > /etc/logrotate.d/gitlab-shell <<EOF
# ${GITLAB_LOG_DIR}/gitlab-shell/*.log {
#   weekly
#   missingok
#   rotate 52
#   compress
#   delaycompress
#   notifempty
#   copytruncate
# }
# EOF

# configure gitlab vhost log rotation
# cat > /etc/logrotate.d/gitlab-nginx <<EOF
# ${GITLAB_LOG_DIR}/nginx/*.log {
#   weekly
#   missingok
#   rotate 52
#   compress
#   delaycompress
#   notifempty
#   copytruncate
# }
# EOF