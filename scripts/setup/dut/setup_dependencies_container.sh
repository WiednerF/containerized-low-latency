#!/bin/bash

#bind RCU Process to core 0 as recommended with  https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html-single/performance_tuning_guide/#sect-Red_Hat_Enterprise_Linux-Performance_Tuning_Guide-Configuration
for i in $(pgrep rcu[^c]) ; do taskset -pc 0 "$i" ; done

set -x

# Improving performance for the waiting time as we have no hard-drive to wait for
sysctl  vm.dirty_ratio=5
sysctl  vm.dirty_background_ratio=1

# ============================================================== #
# ================== SETUP LXC ================================= #
# ============================================================== #
PACKAGES="pip lxc debootstrap python3-lxc ethtool"
DEBIAN_FRONTEND=noninteractive apt-get -y update --allow-releaseinfo-change
DEBIAN_FRONTEND=noninteractive apt-get -y install $PACKAGES

# disable apparmor. Apparmor otherwise blocks mounting the rootfs in the containers
aa-teardown

# ============================================================== #
# ================== SETUP virtualbmc-lxc ====================== #
# ============================================================== #

cd /root || exit
git clone https://github.com/AnonymContainer/virtuallxcbmc
cd virtuallxcbmc || exit

# install dependencies
python3 -m pip install -r requirements.txt
# compile project and move the executables to the right locations
python3 setup.py install
# starts the vbmc daemon in the background
vbmcd
