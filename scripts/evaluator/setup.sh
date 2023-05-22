#!/bin/bash

# exit on error
set -e
# log every command
set -x


apt update
DEBIAN_FRONTEND=noninteractive apt install -y postgresql
DEBIAN_FRONTEND=noninteractive apt install -y postgresql-client
DEBIAN_FRONTEND=noninteractive apt install -y parallel
DEBIAN_FRONTEND=noninteractive apt install -y python3-pip
DEBIAN_FRONTEND=noninteractive apt install -y texlive-full
DEBIAN_FRONTEND=noninteractive apt install -y lbzip2
DEBIAN_FRONTEND=noninteractive apt install -y rename
DEBIAN_FRONTEND=noninteractive apt install -y zstd

python3 -m pip install pypacker
python3 -m pip install netifaces
python3 -m pip install pylatex
python3 -m pip install matplotlib
python3 -m pip install pandas
python3 -m pip install pyyaml

mkdir /root/results

