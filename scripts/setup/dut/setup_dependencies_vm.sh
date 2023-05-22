#!/bin/bash

#bind RCU Process to core 0 as recommended with  https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html-single/performance_tuning_guide/#sect-Red_Hat_Enterprise_Linux-Performance_Tuning_Guide-Configuration
for i in $(pgrep rcu[^c]) ; do taskset -pc 0 "$i" ; done

set -x

# Improving performance for the waiting time as we have no hard-drive to wait for
sysctl  vm.dirty_ratio=5
sysctl  vm.dirty_background_ratio=1

DEBIAN_FRONTEND=noninteractive apt-get update --allow-releaseinfo-change
apt install -y virt-manager qemu-system pkg-config libvirt-dev python3-libvirt python3-pip ethtool  # Installing required tools for the virtual machine setup
pip3 install virtualbmc

# starts the vbmc daemon in the background
vbmcd
