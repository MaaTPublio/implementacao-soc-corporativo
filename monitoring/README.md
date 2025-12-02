# Monitoring, Dashboards and Alerts

This directory contains configurations for Wazuh dashboards and alerting.

## Dashboards

### Security Operations Dashboard

**Purpose:** High-level overview of security posture

**Visualizations:**
1. Alert Volume Timeline
2. Alert Severity Distribution (Pie Chart)
3. Top 10 Triggered Rules (Bar Chart)
4. Top 10 Source IPs (Table)
5. Top 10 Agents with Alerts (Table)
6. Geographic Map of Attack Origins
7. Recent Critical Alerts (Data Table)

**Filters:**
- Time range selector
- Alert level filter
- Agent filter
- Rule group filter

### pfSense Firewall Dashboard

**Purpose:** Monitor pfSense firewall and IDS/IPS

**Visualizations:**
1. Firewall Blocks Over Time (Line Chart)
2. Top Blocked IPs (Table)
3. Top Blocked Ports (Bar Chart)
4. Firewall Action Distribution (Pie: Allow/Block)
5. IDS/IPS Alerts by Severity (Bar Chart)
6. VPN Connections Timeline
7. DHCP Leases Activity
8. Authentication Events (Success/Failure)

**Filters:**
- Interface filter (WAN/LAN/DMZ)
- Action filter (Block/Pass)
- Protocol filter

### Endpoint Security Dashboard

**Purpose:** Monitor endpoint security across all agents

**Visualizations:**
1. Agent Status (Active/Disconnected)
2. File Integrity Monitoring Events
3. Rootcheck Alerts
4. Vulnerability Scan Results
5. Top Processes
6. Configuration Changes
7. Compliance Status

### Compliance Dashboard

**Purpose:** Track compliance requirements (PCI DSS, GDPR, HIPAA)

**Visualizations:**
1. Compliance Score by Requirement
2. Failed Compliance Checks
3. Authentication Events Audit
4. File Access Audit Trail
5. Configuration Changes Log
6. Data Access Patterns

## Alerts Configuration

### Email Alerts

Configure in `/var/ossec/etc/ossec.conf`:

```xml
<email_alerts>
  <email_to>soc-team@yourdomain.com</email_to>
  <level>10</level>
  <do_not_delay />
  <do_not_group />
</email_alerts>

<email_alerts>
  <email_to>security-manager@yourdomain.com</email_to>
  <level>12</level>
  <rule_id>100503,100513,100600,100601,100602</rule_id>
  <do_not_delay />
</email_alerts>
```

### Slack Integration

Create integration script `/var/ossec/integrations/custom-slack`:

```bash
#!/bin/bash
# Slack webhook integration

WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# Read alert from stdin
read INPUT_JSON

# Parse JSON and send to Slack
ALERT_ID=$(echo $INPUT_JSON | jq -r '.id')
RULE_DESC=$(echo $INPUT_JSON | jq -r '.rule.description')
RULE_LEVEL=$(echo $INPUT_JSON | jq -r '.rule.level')
AGENT=$(echo $INPUT_JSON | jq -r '.agent.name')

# Determine color based on severity
if [ "$RULE_LEVEL" -ge 12 ]; then
    COLOR="danger"
elif [ "$RULE_LEVEL" -ge 7 ]; then
    COLOR="warning"
else
    COLOR="good"
fi

# Create Slack message
MESSAGE=$(cat <<EOF
{
  "text": "🚨 Wazuh Security Alert",
  "attachments": [{
    "color": "$COLOR",
    "fields": [
      {"title": "Rule", "value": "$RULE_DESC", "short": false},
      {"title": "Severity", "value": "Level $RULE_LEVEL", "short": true},
      {"title": "Agent", "value": "$AGENT", "short": true}
    ]
  }]
}
EOF
)

# Send to Slack
curl -X POST -H 'Content-type: application/json' --data "$MESSAGE" $WEBHOOK_URL
```

Configure in ossec.conf:

```xml
<integration>
  <name>custom-slack</name>
  <hook_url>https://hooks.slack.com/services/YOUR/WEBHOOK/URL</hook_url>
  <level>7</level>
  <alert_format>json</alert_format>
</integration>
```

### PagerDuty Integration

```xml
<integration>
  <name>pagerduty</name>
  <api_key>YOUR_PAGERDUTY_API_KEY</api_key>
  <level>12</level>
  <alert_format>json</alert_format>
</integration>
```

### Custom Webhook

```xml
<integration>
  <name>custom-webhook</name>
  <hook_url>https://your-webhook-endpoint.com/alerts</hook_url>
  <level>10</level>
  <alert_format>json</alert_format>
  <options>{"header": "Authorization: Bearer YOUR_TOKEN"}</options>
</integration>
```

## Alert Rules

### Critical Alerts (Level 12+)

- Successful privilege escalation
- Rootkit detected
- Critical vulnerability exploited
- System file modification
- Multiple failed authentication attempts

### High Priority (Level 10-11)

- Multiple firewall blocks from same source
- IDS/IPS critical alerts
- Brute force attempts
- Suspicious file modifications
- Malware detected

### Medium Priority (Level 7-9)

- Authentication failures
- Port scans
- Configuration changes
- Unusual network activity
- Policy violations

### Low Priority (Level 1-6)

- Informational events
- Successful logins
- Normal system operations
- Routine configuration changes

## Scheduled Reports

### Daily Security Report

```bash
#!/bin/bash
# Generate daily security report

DATE=$(date +%Y-%m-%d)
REPORT_FILE="/var/ossec/reports/security-report-$DATE.pdf"

# Query Wazuh API for last 24h data
curl -k -X GET "https://localhost:55000/security/alerts?limit=1000" \
  -H "Authorization: Bearer $WAZUH_API_TOKEN" > /tmp/alerts.json

# Generate report (pseudo-code)
# - Parse JSON
# - Create summary statistics
# - Generate PDF report
# - Email to stakeholders
```

### Weekly Compliance Report

```bash
#!/bin/bash
# Generate weekly compliance report

# Query compliance data
# Analyze PCI DSS requirements
# Generate compliance score
# Create report PDF
# Email to compliance team
```

### Monthly Trend Analysis

```bash
#!/bin/bash
# Generate monthly trend analysis

# Aggregate data for past month
# Analyze trends
# Identify patterns
# Generate executive summary
# Email to management
```

## Metrics and KPIs

### Security Metrics

1. **MTTD (Mean Time to Detect)**
   - Average time from incident occurrence to detection
   - Target: < 5 minutes

2. **MTTR (Mean Time to Respond)**
   - Average time from detection to response
   - Target: < 15 minutes

3. **Alert Volume**
   - Total alerts per day
   - Track trends over time

4. **False Positive Rate**
   - Percentage of alerts that are false positives
   - Target: < 10%

5. **Coverage**
   - Percentage of assets monitored
   - Target: 100%

### Operational Metrics

1. **Agent Connectivity**
   - Percentage of agents connected
   - Target: > 99%

2. **Log Ingestion Rate**
   - Events per second (EPS)
   - Monitor for anomalies

3. **Storage Utilization**
   - Disk usage for indices
   - Alert before reaching capacity

4. **Query Performance**
   - Dashboard load times
   - Search query response times

## Visualization Best Practices

1. **Use appropriate chart types**
   - Time series → Line charts
   - Distributions → Pie charts
   - Comparisons → Bar charts
   - Geographic data → Maps

2. **Apply consistent color coding**
   - Red: Critical/Danger
   - Orange: Warning
   - Yellow: Caution
   - Green: Normal/Success
   - Blue: Informational

3. **Set meaningful time ranges**
   - Real-time: Last 15 minutes
   - Tactical: Last 24 hours
   - Strategic: Last 7-30 days

4. **Use filters effectively**
   - Allow drill-down capabilities
   - Save common filter combinations
   - Share filtered views with team

## Dashboard Refresh Rates

- Real-time monitoring: 5-10 seconds
- Tactical dashboards: 1-5 minutes
- Strategic dashboards: 5-15 minutes
- Reports: Daily/Weekly/Monthly

## Retention Policies

### Alerts
- Critical: 1 year
- High: 6 months
- Medium: 3 months
- Low: 1 month

### Raw Logs
- All logs: 90 days (hot storage)
- Archived: 1 year (cold storage)

### Reports
- All reports: 2 years

## References

- [Wazuh Dashboard Documentation](https://documentation.wazuh.com/current/user-manual/wazuh-dashboard/)
- [Kibana Visualizations Guide](https://www.elastic.co/guide/en/kibana/current/visualize.html)
