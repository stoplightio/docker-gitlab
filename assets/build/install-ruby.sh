#!/bin/bash

set -x

test -z "$RUBY_VERSION" && RUBY_VERSION=2.3.6

yum install which -y

which ruby &>/dev/null
if [[ $? -eq 0 ]]; then
    ruby -v | grep "${RUBY_VERSION:0:5}" &>/dev/null
    if [[ $? -ne 0 ]]; then
        yum remove ruby -y
    else
        exit 0
    fi
fi

mkdir /tmp/ruby && \
    cd /tmp/ruby && \
    curl -sL https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION:0:3}/ruby-${RUBY_VERSION}.tar.gz | tar xz && \
    cd ruby-${RUBY_VERSION} && \
    ./configure --disable-install-rdoc && \
    make && \
    make prefix=/usr/local install

if [[ $? -eq 0 ]]; then
    rm -rf /tmp/ruby
fi
