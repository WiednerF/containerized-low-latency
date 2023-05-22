#!/bin/bash
# Install Libmoon on the containers

# exit on error
set -e
# log every command
set -x

FORWARDER=libmoon

prefix=$(hostname)
# modify dpdk-lua.conf so that it grabs the right cores
cat <<EOF > /root/$FORWARDER/dpdk-conf.lua
DPDKConfig {
  cores = 24,25,26,

  forceNumaNode = 1,

  cli = {
    "--file-prefix", "$prefix",
    "--socket-mem", "512,512,512,512",
  }
}
EOF
