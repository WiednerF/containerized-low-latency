#!/bin/bash

# exit on error
set -e
# log every command
set -x
cat > "~/net.xml" <<-EOF
<network><name>net</name><forward dev='ens2' mode='bridge'><interface dev='ens2' /></forward></network>
EOF

virsh net-define net.xml;
virsh net-start net;

virt-install --cpu host-passthrough --memory 14000 --vcpus=3 --cpuset=24-26 --boot=network --name vm1 --nodisks --network='network=net,mac=52:53:00:00:01,model=virtio' --host-device net_enp33s0f1_68_05_ca_39_5f_b1 --host-device net_enp100s0f1_68_05_ca_3a_a3_5d --noautoconsole --graphics none --dry-run --controller='type=usb,model=none' --print-xml --console 'pty,target_type=virtio' > vm1.xml

virsh define vm1.xml

vbmc add --username ADMIN --password password --port 6001 container1;vbmc start container1

