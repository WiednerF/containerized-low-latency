#!/bin/bash

#Needed for Debugging Purpose (Exiting automatically and Print commands as they are executed)
set -e
set -x


#Installing MoonGen on the MoonGen Node
LOADGEN=moongen


apt-get update
apt-get install -y libssl-dev
git clone --branch dpdk-19.05 --recurse-submodules --jobs 4 https://github.com/emmericp/MoonGen "$LOADGEN"
cd $LOADGEN/
/root/$LOADGEN/build.sh
/root/$LOADGEN/bind-interfaces.sh
/root/$LOADGEN/setup-hugetlbfs.sh
