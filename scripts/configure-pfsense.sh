#!/bin/bash
#
# pfSense Configuration Helper Script
# This script helps configure pfSense remotely via SSH
#
# Usage: ./configure-pfsense.sh <pfsense-ip> <ssh-user>
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 <pfsense-ip> <ssh-user>"
    echo "Example: $0 192.168.1.1 admin"
    exit 1
fi

PFSENSE_IP=$1
SSH_USER=$2

print_message "Configuring pfSense at $PFSENSE_IP"

# Test SSH connection
print_message "Testing SSH connection..."
if ! ssh -o ConnectTimeout=5 $SSH_USER@$PFSENSE_IP "echo 'Connection successful'"; then
    print_error "Cannot connect to pfSense via SSH"
    print_warning "Make sure SSH is enabled on pfSense (System → Advanced → Secure Shell)"
    exit 1
fi

# Get Wazuh server IP
read -p "Enter Wazuh Manager IP address: " WAZUH_IP

if [ -z "$WAZUH_IP" ]; then
    print_error "Wazuh IP is required"
    exit 1
fi

# Configure remote syslog
print_message "Configuring remote syslog..."

ssh $SSH_USER@$PFSENSE_IP << EOF
# Install package if needed
pkg install -y pfSense-pkg-syslog-ng

# Configure syslog in config.xml
# Note: This is a simplified approach. In production, use pfSense API or web interface
echo "Manual configuration required:"
echo "1. Go to Status → System Logs → Settings"
echo "2. Enable Remote Logging"
echo "3. Add remote log server: $WAZUH_IP:514"
echo "4. Select 'Everything' for Remote Syslog Contents"
EOF

print_message "pfSense syslog configuration instructions displayed"

# Configure firewall rules
print_message "You need to manually configure firewall rules:"
echo "1. Go to Firewall → Rules → LAN"
echo "2. Add rule to allow LAN to Wazuh Manager ($WAZUH_IP) on port 514/UDP"
echo ""

# Install Snort/Suricata (optional)
read -p "Do you want instructions to install Snort/Suricata IDS? (y/n): " INSTALL_IDS

if [ "$INSTALL_IDS" = "y" ]; then
    print_message "IDS Installation Instructions:"
    echo ""
    echo "For Snort:"
    echo "1. Go to System → Package Manager"
    echo "2. Search for 'snort' and install"
    echo "3. Go to Services → Snort → Global Settings"
    echo "4. Configure and download rules"
    echo "5. Go to Interfaces tab and add WAN interface"
    echo "6. Enable 'Send Alerts to System Log'"
    echo ""
    echo "For Suricata (recommended):"
    echo "1. Go to System → Package Manager"
    echo "2. Search for 'suricata' and install"
    echo "3. Go to Services → Suricata → Interfaces"
    echo "4. Add WAN interface"
    echo "5. Enable EVE JSON log output"
    echo "6. Enable Syslog output"
    echo ""
fi

# Test syslog
print_message "Testing syslog connection..."
ssh $SSH_USER@$PFSENSE_IP "logger -p local0.info 'Test message from pfSense to Wazuh'"
print_message "Test message sent. Check Wazuh logs with:"
echo "sudo tail -f /var/ossec/logs/ossec.log | grep pfSense"
echo ""

print_message "=== Configuration Summary ==="
echo "pfSense IP: $PFSENSE_IP"
echo "Wazuh IP: $WAZUH_IP"
echo ""
print_warning "Complete the manual steps mentioned above"
print_message "Refer to docs/integration.md for detailed instructions"
