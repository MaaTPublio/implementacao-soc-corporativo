# pfSense Firewall Rules Configuration Guide

This directory contains configuration files and scripts for pfSense firewall.

## Firewall Rules Structure

### Default Rules

1. **WAN Rules** (Firewall → Rules → WAN):
   - Block all incoming by default (implicit deny)
   - Allow established/related connections
   - Allow specific services if needed (VPN, etc.)

2. **LAN Rules** (Firewall → Rules → LAN):
   - Allow LAN to Any (default)
   - Allow LAN to Wazuh Manager (192.168.1.10:514/UDP)
   - Allow LAN to Internet (via NAT)

3. **DMZ Rules** (if applicable):
   - Allow DMZ to Internet (specific ports)
   - Deny DMZ to LAN
   - Allow LAN to DMZ (specific services)

## Recommended Security Rules

### 1. Anti-Spoofing

Block RFC1918 addresses on WAN:
```
Action: Block
Interface: WAN
Protocol: Any
Source: RFC1918 networks
Destination: Any
Description: Block spoofed RFC1918 addresses
```

### 2. Block Bogon Networks

```
Action: Block
Interface: WAN
Protocol: Any
Source: Bogon networks
Destination: Any
Description: Block bogon addresses
```

### 3. Rate Limiting for SSH

```
Action: Pass
Interface: WAN
Protocol: TCP
Source: Any
Destination: Firewall (port 22)
Advanced Options:
  - Max-src-conn-rate: 3/60
  - Max-src-conn: 3
Description: Rate limit SSH connections
```

### 4. Geo-blocking (Optional)

Block traffic from specific countries:
```
Action: Block
Interface: WAN
Protocol: Any
Source: GeoIP Country (e.g., CN, RU)
Destination: Any
Description: Block traffic from specific countries
```

## Syslog Configuration

Configure remote logging to Wazuh:

1. Navigate to **Status → System Logs → Settings**
2. Configure:
   - Enable Remote Logging: ✓
   - Source Address: (leave default)
   - IP Protocol: IPv4
   - Remote log servers: `192.168.1.10:514`
   - Remote Syslog Contents:
     - ✓ Everything
     - ✓ Firewall Events
     - ✓ DHCP Events
     - ✓ Authentication
     - ✓ Portal Auth
     - ✓ VPN Events
     - ✓ Wireless Events

## NAT Configuration

### Port Forwarding Example

For web server in DMZ:
```
Interface: WAN
Protocol: TCP
Destination: WAN address
Destination port: 443
Redirect target IP: 192.168.2.10
Redirect target port: 443
Description: HTTPS to web server
```

### Outbound NAT

Recommended: Hybrid Outbound NAT

## VPN Configuration

### OpenVPN Setup

1. **System → Cert Manager**
   - Create CA
   - Create server certificate
   - Create client certificates

2. **VPN → OpenVPN → Servers**
   - Server mode: Remote Access (SSL/TLS + User Auth)
   - Protocol: UDP on IPv4 only
   - Device mode: tun
   - Interface: WAN
   - Local port: 1194
   - TLS Authentication: Enable
   - Tunnel Network: 10.8.0.0/24

3. **Firewall Rules for OpenVPN**:
   ```
   Action: Pass
   Interface: WAN
   Protocol: UDP
   Source: Any
   Destination: WAN address (port 1194)
   ```

   ```
   Action: Pass
   Interface: OpenVPN
   Protocol: Any
   Source: OpenVPN net
   Destination: LAN net
   ```

## IDS/IPS Configuration

### Snort Configuration

1. Install: **System → Package Manager → Snort**
2. Configure: **Services → Snort**
3. Global Settings:
   - Enable Snort VRT rules
   - Enable OpenAppID
4. Add interface (WAN)
5. Categories: Enable all relevant
6. Logging: Send Alerts to System Log

### Suricata Configuration (Recommended)

1. Install: **System → Package Manager → Suricata**
2. Configure: **Services → Suricata**
3. Global Settings:
   - Update Interval: 12h
   - Enable ET Open rules
4. Add interface (WAN)
5. EVE Output Settings:
   - Enable EVE JSON Log
   - Enable all event types
   - Enable Syslog Output

## Active Response Integration

To allow Wazuh to block IPs automatically:

### Method 1: API (Recommended)

1. Install pfSense API package
2. Create API credentials for Wazuh
3. Configure in Wazuh active response script

### Method 2: SSH

1. Enable SSH on pfSense
2. Generate SSH key on Wazuh server:
   ```bash
   sudo -u wazuh ssh-keygen -t rsa -b 4096
   ```
3. Copy public key to pfSense
4. Test connection

## Backup Configuration

Regular backups are essential:

1. **Diagnostics → Backup & Restore**
2. Download configuration XML
3. Store securely
4. Automate with:
   ```bash
   # On Wazuh server
   scp root@192.168.1.1:/cf/conf/config.xml /backup/pfsense-$(date +%Y%m%d).xml
   ```

## High Availability (Optional)

For production environments:

1. Two pfSense boxes
2. CARP for failover
3. Sync configuration via xmlrpc
4. Shared virtual IPs

## Monitoring

Monitor pfSense performance:

1. **Status → Monitoring**
   - CPU, Memory, Disk
   - Bandwidth usage
   - States table

2. **Status → System Logs**
   - Review firewall logs
   - Check for anomalies
   - Verify syslog forwarding

## Troubleshooting

### Logs not forwarding to Wazuh

1. Check syslog configuration
2. Test with: `logger -p local0.info "Test message"`
3. Verify firewall rules allow UDP 514
4. Check Wazuh is listening: `netstat -ulpn | grep 514`

### Rules not blocking traffic

1. Review rule order (first match wins)
2. Check states: **Diagnostics → States**
3. Reset states if needed
4. Verify interface assignment

### High CPU/Memory

1. Reduce logging verbosity
2. Optimize IDS/IPS rules
3. Check for packet loops
4. Review states table size

## Additional Resources

- [pfSense Documentation](https://docs.netgate.com/pfsense/)
- [pfSense Forum](https://forum.netgate.com/)
- [pfSense Book](https://www.netgate.com/resources/pfsense-book)
