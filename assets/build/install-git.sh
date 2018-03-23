#!/bin/bash

set -ex

test -z "$GIT_VERSION" && GIT_VERSION=2.16.2

yum install -y \
    make \
    gcc \
    zlib-devel \
    perl-CPAN \
    gettext \
    curl-devel \
    expat-devel \
    gettext-devel \
    openssl-devel

mkdir /tmp/git && \
    cd /tmp/git && \
    curl -sL https://www.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz | tar xz && \
    cd git-${GIT_VERSION} && \
    ./configure && \
    make && \
    make prefix=/usr/local install

git --version | grep "${GIT_VERSION}"

rm -rf /tmp/git
