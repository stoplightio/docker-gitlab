#!/bin/bash

# install node
rpm -Uvh https://rpm.nodesource.com/pub_8.x/el/7/x86_64/nodejs-8.9.4-1nodesource.x86_64.rpm

# install yarn
curl -o- -L https://yarnpkg.com/install.sh | bash -s -- --version 1.3.2
