FROM centos:7
LABEL maintainer="ross@stoplight.io"

ENV GITLAB_VERSION=10.3.4 \
    RUBY_VERSION=2.3.6 \
    GOLANG_VERSION=1.9.4 \
    GITLAB_SHELL_VERSION=6.0.3 \
    GITLAB_WORKHORSE_VERSION=3.6.0 \
    GITALY_SERVER_VERSION=0.81.0 \
    GITLAB_USER="git" \
    GITLAB_HOME="/home/git" \
    GITLAB_LOG_DIR="/var/log/gitlab" \
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

# enable epel repository
RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

# enable postgres repository
RUN rpm -Uvh https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm

# install build and runtime dependencies
RUN yum install -y \
    sudo \
    wget \
    libicu-devel \
    gcc-c++ \
    cmake \
    bzip2 \
    mysql-devel \
    postgresql-devel \
    postgresql96 \
    re2-devel \
    nginx \
    supervisor \
    redis

# install local packages
COPY assets/packages /tmp/
RUN yum localinstall /tmp/*rpm -y

# configure supervisord
COPY assets/build/configure-supervisor.sh ${GITLAB_BUILD_DIR}/
RUN bash ${GITLAB_BUILD_DIR}/configure-supervisor.sh

# configure nginx
COPY assets/build/configure-nginx.sh ${GITLAB_BUILD_DIR}/
RUN bash ${GITLAB_BUILD_DIR}/configure-nginx.sh

# create gitlab user
RUN adduser --shell /bin/false ${GITLAB_USER} && \
    passwd -d ${GITLAB_USER}

# unpack gitlab
COPY assets/gitlab-10.3.4_full.tar.gz /tmp/
RUN tar -xf /tmp/gitlab-10.3.4_full.tar.gz -C /home/git/ && \
    cp -f /home/git/gitaly/gitaly /usr/local/bin/ && \
    cp -f /home/git/gitlab-pages/gitlab-pages /usr/local/bin/

# purge build dependencies and cleanup yum
RUN yum autoremove -y && \
    rm -rf /var/cache/yum/*

COPY assets/runtime/ ${GITLAB_RUNTIME_DIR}/
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

EXPOSE 22/tcp 80/tcp 443/tcp

VOLUME ["${GITLAB_DATA_DIR}", "${GITLAB_LOG_DIR}"]
WORKDIR ${GITLAB_INSTALL_DIR}
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:start"]
