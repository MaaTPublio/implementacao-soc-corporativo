#!/bin/bash
#
# pfSense IP Blocking Script via Active Response
# This script is called by Wazuh active response to block IPs on pfSense
#
# Usage: pfsense-block.sh add <action> <srcip>
#        pfsense-block.sh delete <action> <srcip>
#

# pfSense Configuration
PFSENSE_HOST="192.168.1.1"
PFSENSE_API_KEY="YOUR_API_KEY"
PFSENSE_API_SECRET="YOUR_API_SECRET"

# Path for logging
LOG_FILE="/var/ossec/logs/active-responses.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - pfsense-block.sh: $1" >> $LOG_FILE
}

# Get parameters
ACTION=$1
USER=$2
IP=$3

# Validate parameters
if [ -z "$ACTION" ] || [ -z "$IP" ]; then
    log_message "ERROR: Missing parameters. Usage: $0 <add|delete> <user> <ip>"
    exit 1
fi

log_message "Received action: $ACTION for IP: $IP"

# Function to add firewall block rule via pfSense API
add_block_rule() {
    local ip=$1
    
    log_message "Adding block rule for IP: $ip"
    
    # Create firewall rule via API
    RESPONSE=$(curl -sk -X POST "https://$PFSENSE_HOST/api/v1/firewall/rule" \
        -u "$PFSENSE_API_KEY:$PFSENSE_API_SECRET" \
        -H "Content-Type: application/json" \
        -d "{
            \"type\": \"block\",
            \"interface\": \"wan\",
            \"ipprotocol\": \"inet\",
            \"protocol\": \"any\",
            \"src\": \"$ip\",
            \"dst\": \"any\",
            \"descr\": \"Wazuh Active Response - Blocked at $(date)\",
            \"top\": true
        }" 2>&1)
    
    if [ $? -eq 0 ]; then
        log_message "Successfully added block rule for $ip"
        
        # Apply changes
        curl -sk -X POST "https://$PFSENSE_HOST/api/v1/firewall/apply" \
            -u "$PFSENSE_API_KEY:$PFSENSE_API_SECRET"
        
        log_message "Firewall rules applied"
    else
        log_message "ERROR: Failed to add block rule for $ip: $RESPONSE"
    fi
}

# Function to remove block rule
delete_block_rule() {
    local ip=$1
    
    log_message "Removing block rule for IP: $ip"
    
    # Find and delete the rule
    # This is a simplified version - in production, track rule IDs
    RULE_ID=$(curl -sk -X GET "https://$PFSENSE_HOST/api/v1/firewall/rule" \
        -u "$PFSENSE_API_KEY:$PFSENSE_API_SECRET" | \
        jq -r ".data[] | select(.src==\"$ip\") | .id" 2>/dev/null | head -1)
    
    if [ -n "$RULE_ID" ]; then
        curl -sk -X DELETE "https://$PFSENSE_HOST/api/v1/firewall/rule/$RULE_ID" \
            -u "$PFSENSE_API_KEY:$PFSENSE_API_SECRET"
        
        # Apply changes
        curl -sk -X POST "https://$PFSENSE_HOST/api/v1/firewall/apply" \
            -u "$PFSENSE_API_KEY:$PFSENSE_API_SECRET"
        
        log_message "Successfully removed block rule for $ip (ID: $RULE_ID)"
    else
        log_message "WARNING: No rule found for IP $ip"
    fi
}

# Alternative method using SSH (if API is not available)
add_block_ssh() {
    local ip=$1
    
    log_message "Adding block via SSH for IP: $ip"
    
    # Using pfSense shell to add rule to table
    ssh -i /var/ossec/.ssh/pfsense_key root@$PFSENSE_HOST \
        "pfctl -t blocklist -T add $ip" 2>&1 | tee -a $LOG_FILE
    
    if [ $? -eq 0 ]; then
        log_message "Successfully blocked $ip via SSH"
    else
        log_message "ERROR: Failed to block $ip via SSH"
    fi
}

delete_block_ssh() {
    local ip=$1
    
    log_message "Removing block via SSH for IP: $ip"
    
    ssh -i /var/ossec/.ssh/pfsense_key root@$PFSENSE_HOST \
        "pfctl -t blocklist -T delete $ip" 2>&1 | tee -a $LOG_FILE
    
    if [ $? -eq 0 ]; then
        log_message "Successfully unblocked $ip via SSH"
    else
        log_message "ERROR: Failed to unblock $ip via SSH"
    fi
}

# Main logic
case "$ACTION" in
    add)
        # Try API first, fall back to SSH
        if [ -n "$PFSENSE_API_KEY" ] && [ "$PFSENSE_API_KEY" != "YOUR_API_KEY" ]; then
            add_block_rule "$IP"
        else
            log_message "API credentials not configured, trying SSH method"
            add_block_ssh "$IP"
        fi
        ;;
    delete)
        if [ -n "$PFSENSE_API_KEY" ] && [ "$PFSENSE_API_KEY" != "YOUR_API_KEY" ]; then
            delete_block_rule "$IP"
        else
            log_message "API credentials not configured, trying SSH method"
            delete_block_ssh "$IP"
        fi
        ;;
    *)
        log_message "ERROR: Invalid action: $ACTION. Use 'add' or 'delete'"
        exit 1
        ;;
esac

exit 0
