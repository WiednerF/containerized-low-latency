#!/bin/bash

# Do not use too much as otherwise the evaluation will fail, require a significant amount of disk and memory space
NUM_CORES=4

# Used for the evaluator scripts
git clone https://github.com/AnonymContainer/containierized-low-latency/ /root/containierized-low-latency

# Download PCAPs to /root/results
cd /root/results
#Will be available when Double Blind is not necessary anymore due to deanonymization on shared link.

env --chdir /var/lib/postgresql setpriv --init-groups --reuid postgres -- createuser -s root || true

# import and analyze to database
mkdir /root/results/data
cd /root/results/data

parallel -j $NUM_CORES "dropdb --if-exists root{ % }; createdb root{ % }; export PGDATABASE=root{ % }; ~/containierized-low-latency/scripts/evaluator/dbscripts/import.sh {}; ~/containierized-low-latency/scripts/evaluator/analysis.sh {}" ::: ../latencies-pre.pcap*.zst

# After this under the folder /root/results/data all required CSVs are available

# When using the precompiled CSV data, decompress them first and then put them into /root/results/data for generation of Figures

# Copy required files for plotting
cp -r ~/containierized-low-latency/scripts/evaluator/plotter/* ~/results

cd ~/results
mkdir figures

python3 plotcreator.py figures data .
make -i

# All compiled figures are now available under ~/results/figures
