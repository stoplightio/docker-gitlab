FROM sameersbn/ubuntu:16.04.20180706
LABEL maintainer="support@stoplight.io"

ENV GITLAB_VERSION=11.0.6 \
     RUBY_VERSION=2.4 \
     GOLANG_VERSION=1.10.3 \
     GITLAB_SHELL_VERSION=7.1.4 \
     GITLAB_WORKHORSE_VERSION=4.3.1 \
     GITLAB_PAGES_VERSION=0.9.1 \
     GITALY_SERVER_VERSION=0.105.0 \
     GITLAB_USER="git" \
     GITLAB_HOME="/home/git" \
     GITLAB_LOG_DIR="/home/git/logs" \
     GITLAB_CACHE_DIR="/etc/docker-gitlab" \
     RAILS_ENV=production \
     NODE_ENV=production

ENV GITLAB_INSTALL_DIR="${GITLAB_HOME}/gitlab" \
     GITLAB_SHELL_INSTALL_DIR="${GITLAB_HOME}/gitlab-shell" \
     GITLAB_WORKHORSE_INSTALL_DIR="${GITLAB_HOME}/gitlab-workhorse" \
     GITLAB_PAGES_INSTALL_DIR="${GITLAB_HOME}/gitlab-pages" \
     GITLAB_GITALY_INSTALL_DIR="${GITLAB_HOME}/gitaly" \
     GITLAB_DATA_DIR="${GITLAB_HOME}/data" \
     GITLAB_BUILD_DIR="${GITLAB_CACHE_DIR}/build" \
     GITLAB_RUNTIME_DIR="${GITLAB_CACHE_DIR}/runtime"

RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv E1DD270288B4E6030699E45FA1715D88E1DF1F24 \
     && echo "deb http://ppa.launchpad.net/git-core/ppa/ubuntu xenial main" >> /etc/apt/sources.list \
     && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 80F70E11F0F0D5F10CB20E62F5DA5F09C3173AA6 \
     && echo "deb http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu xenial main" >> /etc/apt/sources.list \
     && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 8B3981E7A6852F782CC4951600A6F0A3C300EE8C \
     && echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu xenial main" >> /etc/apt/sources.list \
     && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
     && echo 'deb http://apt.postgresql.org/pub/repos/apt/ xenial-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
     && wget --quiet -O - https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
     && echo 'deb https://deb.nodesource.com/node_8.x xenial main' > /etc/apt/sources.list.d/nodesource.list \
     && wget --quiet -O - https://dl.yarnpkg.com/debian/pubkey.gpg  | apt-key add - \
     && echo 'deb https://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list \
     && apt-get update \
     && DEBIAN_FRONTEND=noninteractive apt-get install -y supervisor logrotate locales curl \
     nginx openssh-server mysql-client postgresql-client redis-tools \
     git-core ruby${RUBY_VERSION} python2.7 python-docutils nodejs yarn gettext-base \
     libmysqlclient20 libpq5 zlib1g libyaml-0-2 libssl1.0.0 \
     libgdbm3 libreadline6 libncurses5 libffi6 \
     libxml2 libxslt1.1 libcurl3 libicu55 \
     libre2-dev \
     tzdata \
     && update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX \
     && locale-gen en_US.UTF-8 \
     && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales \
     && gem install --no-document bundler \
     && rm -rf /var/lib/apt/lists/*

COPY assets/build/ ${GITLAB_BUILD_DIR}/
RUN bash ${GITLAB_BUILD_DIR}/install.sh

COPY assets/runtime/ ${GITLAB_RUNTIME_DIR}/
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

RUN mkdir -p ${GITLAB_LOG_DIR} && chmod -R 775 ${GITLAB_LOG_DIR} && chgrp -R 0 ${GITLAB_LOG_DIR}
RUN mkdir -p ${GITLAB_DATA_DIR} && chmod -R 775 ${GITLAB_LOG_DIR} && chgrp -R 0 ${GITLAB_DATA_DIR}
RUN chgrp -R 0 ${GITLAB_HOME} && chmod -R 775 ${GITLAB_HOME}
RUN chgrp -R 0 /etc/nginx && chmod -R 775 /etc/nginx && chmod -R g=u /etc/nginx
RUN chgrp -R 0 /var/lib/nginx && chmod -R 775 /var/lib/nginx
RUN chgrp -R 0 /etc/supervisor && chmod -R 775 /etc/supervisor
RUN chgrp -R 0 /etc/default && chmod -R 775 /etc/default
COPY assets/supervisord.conf /etc/supervisor/supervisord.conf
ENV GITLAB_PORT 8000

RUN chgrp -R 0 /var/log/nginx && chmod -R 755 /var/log/nginx
RUN sed -i 's/pid.*/pid \/tmp\/nginx.pid;/' /etc/nginx/nginx.conf

EXPOSE 8000/tcp

USER 1001:0
VOLUME ["${GITLAB_DATA_DIR}", "${GITLAB_LOG_DIR}"]
WORKDIR ${GITLAB_INSTALL_DIR}
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:start"]
