#!/bin/bash
#
# Wazuh Manager Installation Script
# For Ubuntu 20.04/22.04 and CentOS 8
#
# Usage: sudo ./install-wazuh.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    print_error "Cannot detect OS"
    exit 1
fi

print_message "Detected OS: $OS $VER"

# Install dependencies
print_message "Installing dependencies..."

if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    apt update
    apt install -y curl apt-transport-https lsb-release gnupg wget
elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
    yum install -y curl wget gnupg
else
    print_error "Unsupported OS: $OS"
    exit 1
fi

# Ask user for installation method
print_message "Choose installation method:"
echo "1) Automated (recommended - installs all components)"
echo "2) Manual (install components separately)"
read -p "Enter choice [1-2]: " choice

if [ "$choice" = "1" ]; then
    print_message "Starting automated Wazuh installation..."
    
    # Download installation script
    curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh
    
    # Run installer
    bash ./wazuh-install.sh -a
    
    if [ $? -eq 0 ]; then
        print_message "Wazuh installation completed successfully!"
        print_message "Credentials are saved in wazuh-install-files.tar"
        print_warning "Please save these credentials securely!"
        
        # Extract and display credentials
        tar -xf wazuh-install-files.tar wazuh-passwords.txt
        cat wazuh-passwords.txt
    else
        print_error "Installation failed"
        exit 1
    fi
    
elif [ "$choice" = "2" ]; then
    print_message "Manual installation selected"
    
    # Add Wazuh repository
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
        chmod 644 /usr/share/keyrings/wazuh.gpg
        echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list
        apt update
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH
        cat > /etc/yum.repos.d/wazuh.repo << EOF
[wazuh]
gpgcheck=1
gpgkey=https://packages.wazuh.com/key/GPG-KEY-WAZUH
enabled=1
name=EL-\$releasever - Wazuh
baseurl=https://packages.wazuh.com/4.x/yum/
protect=1
EOF
    fi
    
    # Install Wazuh Manager
    print_message "Installing Wazuh Manager..."
    if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
        apt install -y wazuh-manager
    elif [ "$OS" = "centos" ] || [ "$OS" = "rhel" ]; then
        yum install -y wazuh-manager
    fi
    
    # Enable and start service
    systemctl daemon-reload
    systemctl enable wazuh-manager
    systemctl start wazuh-manager
    
    print_message "Wazuh Manager installed successfully"
    print_warning "You still need to install Wazuh Indexer and Dashboard manually"
    print_message "Refer to: https://documentation.wazuh.com/current/installation-guide/"
    
else
    print_error "Invalid choice"
    exit 1
fi

# Configure firewall
print_message "Configuring firewall..."

if command -v ufw &> /dev/null; then
    ufw allow 1514/tcp comment 'Wazuh agents'
    ufw allow 1515/tcp comment 'Wazuh enrollment'
    ufw allow 514/udp comment 'Syslog'
    ufw allow 55000/tcp comment 'Wazuh API'
    ufw allow 443/tcp comment 'Wazuh Dashboard'
    print_message "UFW rules added"
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-port=1514/tcp
    firewall-cmd --permanent --add-port=1515/tcp
    firewall-cmd --permanent --add-port=514/udp
    firewall-cmd --permanent --add-port=55000/tcp
    firewall-cmd --permanent --add-port=443/tcp
    firewall-cmd --reload
    print_message "Firewalld rules added"
else
    print_warning "No firewall detected. Please open ports manually: 1514/tcp, 1515/tcp, 514/udp, 55000/tcp, 443/tcp"
fi

# Configure syslog reception
print_message "Configuring syslog reception for pfSense..."

read -p "Enter pfSense IP address (e.g., 192.168.1.1): " PFSENSE_IP

if [ -n "$PFSENSE_IP" ]; then
    # Backup original config
    cp /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.conf.backup
    
    # Add remote syslog configuration
    sed -i "/<\/global>/a \
  <remote>\n\
    <connection>syslog</connection>\n\
    <port>514</port>\n\
    <protocol>udp</protocol>\n\
    <allowed-ips>$PFSENSE_IP</allowed-ips>\n\
  </remote>" /var/ossec/etc/ossec.conf
    
    print_message "Syslog configuration added for pfSense IP: $PFSENSE_IP"
    
    # Restart Wazuh
    systemctl restart wazuh-manager
    print_message "Wazuh Manager restarted"
fi

# Display status
print_message "Checking Wazuh Manager status..."
systemctl status wazuh-manager --no-pager

# Display next steps
echo ""
print_message "=== Installation Complete ==="
echo ""
print_message "Next steps:"
echo "1. Configure pfSense to send logs to this server"
echo "2. Install Wazuh agents on endpoints"
echo "3. Access Wazuh Dashboard at https://$(hostname -I | awk '{print $1}')"
echo "4. Review configuration in /var/ossec/etc/ossec.conf"
echo "5. Add custom rules and decoders from this repository"
echo ""
print_warning "Remember to secure your installation and change default passwords!"
echo ""
