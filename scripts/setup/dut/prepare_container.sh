#!/bin/bash
DEBIAN_FRONTEND=noninteractive apt-get -y install openssh-server policykit-1 locales-all libnss-resolve

# Remove /etc/hostname so that the system doesn't have a static hostname. This
# signals systemd-hostnamed that it's ok to use the transient hostname received
# via DHCP (see also hostnamectl(1)).
rm --force -- "/etc/hostname"

# Configure the system locale
echo 'LANG=en_US.UTF8' > "/etc/locale.conf"


# Enable systemd-networkd so it can manage the management interface
systemctl enable 'systemd-networkd.service' > /dev/null

# Enable systemd-resolved so we have working DNS on the management interface
systemctl enable 'systemd-resolved.service' > /dev/null

# Configure SSH according to these requirements:
#   1. Password-based login MUST NOT be allowed
#   2. PAM MUST be enabled so login tracking via logind works and environment
#      settings in /etc/environment take effect
#   3. SFTP MUST be enabled so users can easily transfer data to and from the
#      test nodes
cat > "/etc/ssh/sshd_config" <<-EOF
	ChallengeResponseAuthentication no
	PasswordAuthentication no
	PrintMotd no
	Subsystem sftp internal-sftp
	UsePam yes
EOF
