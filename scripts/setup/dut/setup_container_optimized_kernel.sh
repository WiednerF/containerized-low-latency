#!/bin/bash

# exit on error
set -e
# log every command
set -x

ip link del lxcbr0;

ip link add name br0 type bridge;
sleep 1;
# A DHCP address is needed for this MAC from the outside
ip link set dev br0 address 52:54:00:00:01;
sleep 1;
ip link set br0 up;

# Need to be the interface for remote controlling and SSH access to the hardware device
ip link set ens2 master br0;


cat > "/etc/systemd/network/00-management.network" <<-EOF
[Match]
MACAddress=52:54:00:00:01
Name=br0

[Network]
DHCP=yes

[DHCP]
UseDomains=yes
EOF
systemctl restart systemd-networkd;

# Needed to make sure that the bridge owns the external IP address
ip addr del "$(ip addr show dev ens2| awk -F ' *|:' '/inet /{{print $3}}')" dev ens2;

apt update;

lxc-create -n container1 -t debian -- --arch amd64 --release bullseye


tee -a /var/lib/lxc/container1/config << END
lxc.net.0.type = veth
lxc.net.0.link = br0
lxc.net.0.name = eth0
lxc.net.0.hwaddr = 52:53:00:00:02
lxc.net.0.flags = up

lxc.mount.auto =
lxc.mount.auto = 'proc:rw sys:rw' 'proc:rw sys:rw'

lxc.net.1.type = 'phys'
lxc.net.2.type = 'phys'
lxc.net.1.link = enp33s0f1
lxc.net.2.link = enp100s0f1
lxc.net.1.name = ens3
lxc.net.2.name = ens4
lxc.net.1.hwaddr = 52:53:00:00:03
lxc.net.1.flags = up
lxc.net.2.hwaddr = 52:53:00:00:04
lxc.net.2.flags = up

lxc.cgroup2.cpuset.cpus = 24-26
lxc.cgroup2.memory.max = 14000000000
lxc.cgroup2.cpuset.cpus.partition = 'root' 

END

lxc-start -n container1

# Requires the prepare_container.sh script on the path of this script for execution
cat "prepare_container.sh" | lxc-attach -n container1 -- sh

lxc-attach -n container1 --  /bin/bash -c 'mkdir /root/.ssh'

# For later access the SSH files need to be on the selected location
cat "/root/.ssh/authorized_keys" |  lxc-attach -n container1 -- /bin/sh -c '/bin/cat > /root/.ssh/authorized_keys'

lxc-attach -n container1 --  /bin/bash -c 'systemctl set-property system.slice AllowedCPUs=24; systemctl set-property init.scope AllowedCPUs=24;'


vbmc add --username ADMIN --password password --port 6001 container1;vbmc start container1

lxc-stop -n container1

lxc-start -n container1
