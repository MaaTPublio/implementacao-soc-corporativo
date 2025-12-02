# Example Configurations

This directory contains example configuration files for various scenarios.

## Quick Start Examples

### 1. Basic Home Lab Setup

**Network:**
- WAN: DHCP from ISP
- LAN: 192.168.1.0/24
- Wazuh Manager: 192.168.1.10

**Components:**
- pfSense (WAN + LAN)
- Wazuh Manager
- 2-3 monitored endpoints

**Use Case:** Learning SOC fundamentals, testing IDS rules

### 2. Small Business Setup

**Network:**
- WAN: Static IP or DHCP
- LAN: 192.168.1.0/24 (workstations)
- DMZ: 192.168.2.0/24 (servers)
- Wazuh Manager: 192.168.1.10

**Components:**
- pfSense with DMZ
- Wazuh Manager + Indexer + Dashboard
- 10-20 endpoints
- Web server in DMZ
- OpenVPN for remote access

**Use Case:** Real-world monitoring, compliance, incident response

### 3. Advanced Enterprise Lab

**Network:**
- WAN: Multiple ISPs (failover)
- LAN: Multiple VLANs
- DMZ: 192.168.2.0/24
- Management: 192.168.0.0/24
- Wazuh Cluster: 192.168.0.10-12

**Components:**
- pfSense HA cluster
- Wazuh cluster (3 managers)
- Elasticsearch cluster
- 50+ endpoints
- Multiple servers
- IDS/IPS on all interfaces

**Use Case:** Enterprise simulation, high availability, scalability testing

## Example Agent Configurations

### Linux Agent (Ubuntu/Debian)

```xml
<agent_config>
  <!-- Syscheck - File Integrity Monitoring -->
  <syscheck>
    <frequency>43200</frequency>
    <scan_on_start>yes</scan_on_start>
    
    <directories check_all="yes" realtime="yes">/etc,/usr/bin,/usr/sbin</directories>
    <directories check_all="yes" realtime="yes">/bin,/sbin</directories>
    <directories check_all="yes">/var/www</directories>
    
    <ignore>/etc/mtab</ignore>
    <ignore>/etc/hosts.deny</ignore>
  </syscheck>

  <!-- Rootcheck -->
  <rootcheck>
    <frequency>43200</frequency>
  </rootcheck>

  <!-- Log collection -->
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/auth.log</location>
  </localfile>

  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/syslog</location>
  </localfile>

  <localfile>
    <log_format>apache</log_format>
    <location>/var/log/apache2/access.log</location>
  </localfile>
</agent_config>
```

### Windows Agent

```xml
<agent_config os="Windows">
  <!-- Syscheck -->
  <syscheck>
    <frequency>43200</frequency>
    <scan_on_start>yes</scan_on_start>
    
    <directories check_all="yes" realtime="yes">C:\Windows\System32</directories>
    <directories check_all="yes">C:\Program Files</directories>
    <directories check_all="yes">C:\Program Files (x86)</directories>
    
    <ignore>C:\Windows\System32\wbem\Performance</ignore>
  </syscheck>

  <!-- Windows Event Log -->
  <localfile>
    <location>Application</location>
    <log_format>eventchannel</log_format>
  </localfile>

  <localfile>
    <location>Security</location>
    <log_format>eventchannel</log_format>
  </localfile>

  <localfile>
    <location>System</location>
    <log_format>eventchannel</log_format>
  </localfile>
</agent_config>
```

### Web Server Agent

```xml
<agent_config>
  <!-- Enhanced monitoring for web server -->
  <syscheck>
    <frequency>21600</frequency>
    <scan_on_start>yes</scan_on_start>
    
    <directories check_all="yes" realtime="yes">/var/www</directories>
    <directories check_all="yes" realtime="yes">/etc/nginx</directories>
    <directories check_all="yes" realtime="yes">/etc/apache2</directories>
  </syscheck>

  <!-- Web server logs -->
  <localfile>
    <log_format>apache</log_format>
    <location>/var/log/nginx/access.log</location>
  </localfile>

  <localfile>
    <log_format>apache</log_format>
    <location>/var/log/nginx/error.log</location>
  </localfile>
</agent_config>
```

## Example Use Cases

### Use Case 1: Detect Brute Force SSH Attack

**Scenario:** Attacker attempts multiple SSH login failures

**Detection:**
1. pfSense logs connection attempts
2. Wazuh detects pattern (5 failures in 5 minutes)
3. Rule 100403 triggers
4. Active response blocks IP

**Rules involved:**
- 100402: SSH authentication failure
- 100403: Multiple failures (brute force)

### Use Case 2: Detect Port Scan

**Scenario:** Attacker scans ports from external IP

**Detection:**
1. pfSense IDS (Snort/Suricata) detects scan
2. Sends alert to Wazuh
3. Wazuh correlates multiple connections
4. Rule 100603 triggers
5. SOC analyst notified

### Use Case 3: Detect Web Attack (SQL Injection)

**Scenario:** SQL injection attempt on web server

**Detection:**
1. pfSense IDS detects SQL injection pattern
2. Wazuh receives IDS alert
3. Rule 100600 triggers (critical)
4. Immediate alert to SOC
5. Active response blocks attacker IP
6. Web server logs analyzed for compromise

### Use Case 4: Insider Threat Detection

**Scenario:** Employee accessing sensitive files at odd hours

**Detection:**
1. Wazuh agent monitors file access
2. Syscheck detects file modifications
3. Correlation with authentication logs
4. Alert on unusual behavior
5. Investigation initiated

## Testing Scenarios

### Test 1: Verify Wazuh-pfSense Integration

```bash
# On pfSense
logger -p local0.info "Test message from pfSense"

# On Wazuh
tail -f /var/ossec/logs/archives/archives.log | grep "Test message"
```

### Test 2: Simulate SSH Brute Force

```bash
# From external host
for i in {1..10}; do
  ssh invaliduser@target-ip
done

# Check Wazuh alerts
tail -f /var/ossec/logs/alerts/alerts.log
```

### Test 3: Simulate Port Scan

```bash
# Using nmap
nmap -sS -p 1-1000 target-ip

# Check pfSense IDS logs and Wazuh
```

### Test 4: Test Active Response

```bash
# Manually trigger active response
/var/ossec/bin/agent_control -b 1.2.3.4

# Verify IP is blocked on pfSense
```

## Dashboard Examples

### Dashboard 1: Security Overview

Widgets:
- Alert volume over time
- Top 10 triggered rules
- Geographic map of attacks
- Critical alerts list

### Dashboard 2: pfSense Monitoring

Widgets:
- Firewall blocks by source IP
- Top blocked ports
- IDS/IPS alerts by severity
- VPN connections timeline

### Dashboard 3: Compliance

Widgets:
- PCI DSS compliance status
- File integrity monitoring events
- Authentication events
- Vulnerability scan results

## Alert Templates

### Email Alert Template

```
Subject: [Wazuh Alert] {rule.level} - {rule.description}

Alert ID: {alert.id}
Time: {timestamp}
Rule: {rule.id} - {rule.description}
Level: {rule.level}
Source IP: {data.srcip}
Agent: {agent.name}

Full Log:
{full_log}

Actions taken:
- Alert logged
- SOC notified
{active_response_actions}
```

### Slack Alert Template

```json
{
  "text": "Wazuh Alert",
  "attachments": [
    {
      "color": "danger",
      "fields": [
        {"title": "Rule", "value": "{rule.id} - {rule.description}"},
        {"title": "Level", "value": "{rule.level}", "short": true},
        {"title": "Agent", "value": "{agent.name}", "short": true},
        {"title": "Source IP", "value": "{data.srcip}"}
      ]
    }
  ]
}
```

## Compliance Templates

### PCI DSS

Requirements mapping:
- 10.2: Audit trail for system events
- 10.3: Audit trail entries
- 11.4: IDS/IPS usage
- 11.5: File integrity monitoring

### GDPR

Controls:
- Access logging
- Data breach detection
- Incident response
- Security monitoring

### HIPAA

Controls:
- Access controls (164.312(a)(1))
- Audit controls (164.312(b))
- Integrity controls (164.312(c)(1))
- Transmission security (164.312(e)(1))

## References

- [Wazuh Use Cases](https://documentation.wazuh.com/current/use-cases/)
- [pfSense Best Practices](https://docs.netgate.com/pfsense/en/latest/references/best-practices.html)
