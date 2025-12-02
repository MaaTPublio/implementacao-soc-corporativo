# Wazuh Custom Rules

This directory contains custom detection rules for Wazuh.

## Rules Overview

### pfsense_rules.xml

Custom rules for detecting security events from pfSense logs.

**Rule Categories:**

1. **Firewall Rules (100100-100199)**
   - Firewall blocks
   - Multiple blocks from same source
   - Port scan detection

2. **DHCP Rules (100200-100299)**
   - DHCP leases
   - DHCP denials

3. **VPN Rules (100300-100399)**
   - OpenVPN connections
   - VPN authentication failures
   - Brute force VPN attempts

4. **Authentication Rules (100400-100499)**
   - Web interface logins
   - Failed authentication attempts
   - Brute force detection

5. **IDS/IPS Rules (100500-100699)**
   - Snort/Suricata alerts
   - Attack pattern detection
   - SQL injection attempts
   - XSS attacks
   - Exploit detection

## Rule Severity Levels

- **Level 0-3**: Informational
- **Level 4-6**: Low priority
- **Level 7-9**: Medium priority
- **Level 10-12**: High priority
- **Level 13-15**: Critical

## Creating Custom Rules

### Rule Template

```xml
<rule id="UNIQUE_ID" level="SEVERITY">
  <if_sid>PARENT_RULE</if_sid>
  <match>pattern to match</match>
  <description>Clear description of what this detects</description>
  <group>category,subcategory,</group>
</rule>
```

### Example: Detect Specific Attack

```xml
<rule id="100700" level="12">
  <if_sid>100500</if_sid>
  <match>specific_attack_signature</match>
  <description>Specific attack detected from IDS</description>
  <group>ids,attack,custom,</group>
</rule>
```

## Rule Testing

### Using wazuh-logtest

```bash
sudo /var/ossec/bin/wazuh-logtest
```

Then paste a sample log entry to test if rules match correctly.

### Test with Sample Logs

```bash
# Test pfSense firewall log
echo "filterlog: 5,16777216,,1000000103,em0,match,block,in,4,0x0,,64,0,0,DF,6,tcp,60,192.168.1.100,8.8.8.8,12345,80,0,S,1234567890,,1024,,mss" | sudo /var/ossec/bin/wazuh-logtest
```

## Rule Best Practices

1. **Use meaningful IDs**: Group related rules with sequential IDs
2. **Set appropriate levels**: Don't over-alert (too high) or under-alert (too low)
3. **Clear descriptions**: Help analysts understand what was detected
4. **Use groups**: Categorize rules for easier filtering
5. **Test thoroughly**: Verify rules match intended logs
6. **Document changes**: Comment complex rules

## Common Rule Techniques

### Frequency Detection

Detect multiple occurrences:

```xml
<rule id="100800" level="10">
  <if_sid>100100</if_sid>
  <same_source_ip />
  <frequency>10</frequency>
  <timeframe>60</timeframe>
  <description>10 events from same IP in 60 seconds</description>
</rule>
```

### Time-based Detection

Detect events at unusual times:

```xml
<rule id="100801" level="8">
  <if_sid>100400</if_sid>
  <time>10:00 pm - 6:00 am</time>
  <description>Login attempt during off-hours</description>
</rule>
```

### Geographic Detection

Match specific locations:

```xml
<rule id="100802" level="9">
  <if_sid>100400</if_sid>
  <srcgeoip>CN,RU,KP</srcgeoip>
  <description>Login from high-risk country</description>
</rule>
```

## Tuning Rules

### Reducing False Positives

1. **Add exceptions**:
```xml
<rule id="100803" level="0">
  <if_sid>100802</if_sid>
  <srcip>trusted.ip.address</srcip>
  <description>Whitelist trusted IP</description>
</rule>
```

2. **Adjust thresholds**: Change frequency/timeframe values
3. **Refine patterns**: Make match conditions more specific

### Increasing Detection

1. Lower thresholds for critical systems
2. Add correlation between multiple events
3. Create composite rules

## Installation

1. Copy rules file:
```bash
sudo cp pfsense_rules.xml /var/ossec/etc/rules/
```

2. Set permissions:
```bash
sudo chown wazuh:wazuh /var/ossec/etc/rules/pfsense_rules.xml
sudo chmod 640 /var/ossec/etc/rules/pfsense_rules.xml
```

3. Test configuration:
```bash
sudo /var/ossec/bin/wazuh-logtest -t
```

4. Restart Wazuh:
```bash
sudo systemctl restart wazuh-manager
```

## Troubleshooting

### Rules not triggering

1. Check rule syntax
2. Verify parent rule ID exists
3. Test with logtest
4. Check decoder is parsing logs correctly
5. Review rule level (may be filtered out)

### Too many alerts

1. Increase rule level threshold
2. Add frequency requirements
3. Create exceptions for known-good sources
4. Adjust timeframe

## References

- [Wazuh Rules Syntax](https://documentation.wazuh.com/current/user-manual/ruleset/rules-classification.html)
- [Custom Rules](https://documentation.wazuh.com/current/user-manual/ruleset/custom.html)
- [Rule Testing](https://documentation.wazuh.com/current/user-manual/ruleset/testing.html)
