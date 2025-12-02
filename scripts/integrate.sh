#!/bin/bash
#
# Integration Script - Wazuh + pfSense
# This script integrates Wazuh with pfSense
#
# Usage: sudo ./integrate.sh
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

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root (use sudo)"
    exit 1
fi

# Check if Wazuh is installed
if ! systemctl is-active --quiet wazuh-manager; then
    print_error "Wazuh Manager is not running. Please install it first."
    exit 1
fi

print_message "=== Wazuh-pfSense Integration Script ==="
echo ""

# Get repository path
REPO_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
print_message "Repository path: $REPO_PATH"

# Copy custom decoders
print_message "Installing pfSense decoders..."
if [ -f "$REPO_PATH/wazuh/decoders/pfsense_decoders.xml" ]; then
    cp "$REPO_PATH/wazuh/decoders/pfsense_decoders.xml" /var/ossec/etc/decoders/
    chown wazuh:wazuh /var/ossec/etc/decoders/pfsense_decoders.xml
    chmod 640 /var/ossec/etc/decoders/pfsense_decoders.xml
    print_message "Decoders installed"
else
    print_warning "Decoder file not found: $REPO_PATH/wazuh/decoders/pfsense_decoders.xml"
fi

# Copy custom rules
print_message "Installing pfSense rules..."
if [ -f "$REPO_PATH/wazuh/rules/pfsense_rules.xml" ]; then
    cp "$REPO_PATH/wazuh/rules/pfsense_rules.xml" /var/ossec/etc/rules/
    chown wazuh:wazuh /var/ossec/etc/rules/pfsense_rules.xml
    chmod 640 /var/ossec/etc/rules/pfsense_rules.xml
    print_message "Rules installed"
else
    print_warning "Rules file not found: $REPO_PATH/wazuh/rules/pfsense_rules.xml"
fi

# Configure remote syslog
read -p "Enter pfSense IP address: " PFSENSE_IP

if [ -n "$PFSENSE_IP" ]; then
    # Backup config
    cp /var/ossec/etc/ossec.conf /var/ossec/etc/ossec.conf.backup.$(date +%Y%m%d_%H%M%S)
    
    # Check if remote syslog already configured
    if grep -q "<connection>syslog</connection>" /var/ossec/etc/ossec.conf; then
        print_warning "Syslog configuration already exists. Skipping..."
    else
        # Add remote configuration
        print_message "Adding remote syslog configuration..."
        
        # Create temporary config snippet
        cat > /tmp/remote_config.xml << EOF
  <remote>
    <connection>syslog</connection>
    <port>514</port>
    <protocol>udp</protocol>
    <allowed-ips>$PFSENSE_IP</allowed-ips>
  </remote>
EOF
        
        # Insert after </global> tag
        sed -i "/<\/global>/r /tmp/remote_config.xml" /var/ossec/etc/ossec.conf
        rm /tmp/remote_config.xml
        
        print_message "Remote syslog configured for IP: $PFSENSE_IP"
    fi
fi

# Test configuration
print_message "Testing Wazuh configuration..."
if /var/ossec/bin/wazuh-logtest -t 2>&1 | grep -q "wazuh-logtest: Testing configuration"; then
    print_error "Configuration test failed. Check /var/ossec/logs/ossec.log"
    exit 1
fi

# Restart Wazuh
print_message "Restarting Wazuh Manager..."
systemctl restart wazuh-manager

# Wait for service to start
sleep 3

# Check status
if systemctl is-active --quiet wazuh-manager; then
    print_message "Wazuh Manager restarted successfully"
else
    print_error "Wazuh Manager failed to start. Check logs:"
    echo "sudo journalctl -u wazuh-manager -n 50"
    exit 1
fi

# Verify ports are listening
print_message "Verifying listening ports..."
if netstat -tulpn | grep -q ":514.*ossec"; then
    print_message "Port 514/UDP is listening for syslog"
else
    print_warning "Port 514 may not be listening. Check configuration."
fi

if netstat -tulpn | grep -q ":1514.*ossec"; then
    print_message "Port 1514/TCP is listening for agents"
else
    print_warning "Port 1514 may not be listening. Check configuration."
fi

# Display next steps
echo ""
print_message "=== Integration Complete ==="
echo ""
print_message "Next steps:"
echo "1. Configure pfSense to send logs to this server:"
echo "   - Go to Status → System Logs → Settings in pfSense"
echo "   - Enable Remote Logging"
echo "   - Add remote server: $(hostname -I | awk '{print $1}'):514"
echo ""
echo "2. Test the integration:"
echo "   - On pfSense: logger -p local0.info 'Test message'"
echo "   - On Wazuh: sudo tail -f /var/ossec/logs/archives/archives.log"
echo ""
echo "3. Install Wazuh agents on endpoints:"
echo "   - Refer to docs/installation.md"
echo ""
echo "4. Configure IDS/IPS on pfSense (Snort or Suricata)"
echo "   - Refer to docs/integration.md"
echo ""
echo "5. Access Wazuh Dashboard to view events:"
echo "   - URL: https://$(hostname -I | awk '{print $1}')"
echo ""
print_warning "Remember to configure firewall rules to allow syslog traffic!"
echo ""
