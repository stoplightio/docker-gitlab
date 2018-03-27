#!/bin/bash

set -x

curl --silent --location https://rpm.nodesource.com/setup_8.x | bash -
curl --silent --location https://dl.yarnpkg.com/rpm/yarn.repo | sudo tee /etc/yum.repos.d/yarn.repo

yum install nodejs yarn -y
