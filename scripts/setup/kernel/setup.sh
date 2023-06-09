#!/bin/bash
# exit on error
set -e
# log every command
set -x

# setup interfaces hardcoded, need to be changed when using another host
INF1="ens3"
INF2="ens4"

ip l set dev $INF1 up
ip l set dev $INF1 promisc on
ip l set dev $INF2 up
ip l set dev $INF2 promisc on

# Enable l2 forwarding on linux
tc qdisc add dev $INF1 ingress
tc filter add dev $INF1 parent ffff: protocol all prio 2 u32 match u32 0 0 flowid 1:1 action mirred egress mirror dev $INF2

