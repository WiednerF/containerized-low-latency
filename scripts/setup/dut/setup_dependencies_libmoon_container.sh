#!/bin/bash

# ============================================================== #
# ================== HOST part ================================= #
# ============================================================== #
# This script prepares the container-host so that guests may have direct access to the NICs, which allows userspace tools
# like DPDK to take control of the NIC within a container.
# A number of steps have to be done to prepare the host - following the notes from murthy krishna at http://mails.dpdk.org/archives/dev/2014-October/006373.html:
# 1. Load uio and igb_uio kernel modules
# 2. Load the patched version of the iavf driver.
# 3. Bind the external NICs, that should be accessible for DPDK to the igb_uio driver
# 4. Create huge tables


# exit on error
set -e
# log every command
set -x

# clone libmoon
GIT_REPO='https://github.com/libmoon/libmoon.git'
GIT_BRANCH='dpdk-19.05'
FORWARDER=libmoon
cd /root

git clone --branch "$GIT_BRANCH" --recurse-submodules --jobs 4 "$GIT_REPO" "$FORWARDER"
cd $FORWARDER/

# build and load igb_uio
cd deps/dpdk-kmods/linux/igb_uio
make
modprobe uio
insmod igb_uio.ko

cd /root/$FORWARDER/deps/dpdk/usertools/
# python dpdk-devbind.py --status
# bind the two external interfaces to igb_uio. find out pci slot with the --status command
# the order matters! the order of the bindings must match with the definition in `external` of a host def.
# The reason is that the /dev/uioX device files are created in the order the drivers are bound to the cards.
# so /dev/uio0 will belong to enp33s0f1, /dev/uio1 will belong to enp100s0f1 in our case, need to be changed accordingly
hostname=$(hostname)
EXTERNAL_INTERFACES="enp33s0f1 enp100s0f1"
IFS=" "
for device_long in $(echo "$EXTERNAL_INTERFACES"); do
  device=$(echo "$device_long" | awk -F '_' '{ print $2 }')
  python dpdk-devbind.py --bind=igb_uio "$device"
done
unset IFS

# create hugetable on the host. Those hugetables will be passed through to the container
bash /root/$FORWARDER/setup-hugetlbfs.sh
