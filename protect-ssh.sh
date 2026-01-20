# 1. Set up firewall
ufw allow OpenSSH
ufw allow 22/tcp
ufw --force enable

# 2. Disable password authentication (SSH keys only)
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# 3. Install fail2ban
apt-get install -y fail2ban

# 4. Set up automatic security updates
apt-get install -y unattended-upgrades
dpkg-reconfigure --priority=low unattended-upgrades