#!/bin/bash

#Install Libmoon on the nodes

# exit on error
set -e
# log every command
set -x

GIT_REPO='https://github.com/libmoon/libmoon.git'
GIT_BRANCH='dpdk-19.05'
FORWARDER=libmoon

#Installing required information
DEBIAN_FRONTEND=noninteractive apt-get update --allow-releaseinfo-change
apt install -y libssl-dev libtbb2

#Install iavf driver
git clone https://github.com/dmarion/iavf.git
cd iavf/src
make install
modprobe iavf
cd /root

git clone --branch "$GIT_BRANCH" --recurse-submodules --jobs 4 "$GIT_REPO" "$FORWARDER"
cd $FORWARDER/
/root/$FORWARDER/build.sh
/root/$FORWARDER/bind-interfaces.sh
/root/$FORWARDER/setup-hugetlbfs.sh
