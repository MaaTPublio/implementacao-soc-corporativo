# Wazuh Custom Decoders

This directory contains custom log decoders for Wazuh.

## Decoders Overview

### pfsense_decoders.xml

Custom decoders for parsing pfSense logs.

**Decoder Categories:**

1. **Filterlog Decoder**: Parses pfSense firewall logs
2. **DHCP Decoder**: Parses DHCP server logs
3. **OpenVPN Decoder**: Parses VPN connection logs
4. **Authentication Decoder**: Parses web interface authentication
5. **IDS/IPS Decoders**: Parse Snort/Suricata alerts

## How Decoders Work

Decoders extract structured data from raw log messages:

```
Raw Log → Decoder → Structured Fields → Rules
```

### Example

**Raw log:**
```
dhcpd: DHCPACK on 192.168.1.100 to aa:bb:cc:dd:ee:ff (hostname) via em1
```

**Decoder extracts:**
- action: DHCPACK
- interface: em1
- ip_address: 192.168.1.100
- mac_address: aa:bb:cc:dd:ee:ff

**Rules can then match** on these fields.

## Decoder Structure

### Basic Decoder

```xml
<decoder name="decoder-name">
  <program_name>^program</program_name>
  <regex>pattern to match</regex>
  <order>field1,field2,field3</order>
</decoder>
```

### Child Decoder

```xml
<decoder name="child-decoder">
  <parent>parent-decoder</parent>
  <regex>specific pattern</regex>
  <order>additional_fields</order>
</decoder>
```

## Field Extraction

### Common Fields

- **srcip**: Source IP address
- **dstip**: Destination IP address
- **srcport**: Source port
- **dstport**: Destination port
- **protocol**: Protocol (TCP, UDP, ICMP)
- **action**: Action taken (allow, block, drop)
- **user**: Username
- **status**: Status code

### pfSense Filterlog Fields

```xml
<order>
  rule_number,
  sub_rule,
  anchor,
  tracker,
  interface,
  reason,
  action,
  direction,
  ip_version,
  tos,
  ecn,
  ttl,
  id,
  offset,
  flags,
  protocol_id,
  protocol,
  length,
  src_ip,
  dst_ip,
  src_port,
  dst_port,
  data_length
</order>
```

## Testing Decoders

### Using wazuh-logtest

```bash
sudo /var/ossec/bin/wazuh-logtest
```

**Test pfSense firewall log:**
```
Type: filterlog: 5,16777216,,1000000103,em0,match,block,in,4,0x0,,64,0,0,DF,6,tcp,60,10.0.0.1,8.8.8.8,12345,80,0,S,1234567890,,1024,,mss

Expected output should show extracted fields:
  - action: 'block'
  - src_ip: '10.0.0.1'
  - dst_ip: '8.8.8.8'
  - src_port: '12345'
  - dst_port: '80'
  - protocol: 'tcp'
```

## Creating Custom Decoders

### Step 1: Identify Log Format

Collect sample logs from the source:
```bash
tail -f /var/log/syslog | grep program_name
```

### Step 2: Create Regex Pattern

Match the log format:
```
Log: "myapp: User john logged in from 192.168.1.10"
Regex: User (\S+) logged in from (\S+)
```

### Step 3: Define Decoder

```xml
<decoder name="myapp">
  <program_name>^myapp</program_name>
</decoder>

<decoder name="myapp-login">
  <parent>myapp</parent>
  <regex>User (\S+) logged in from (\S+)</regex>
  <order>user,srcip</order>
</decoder>
```

### Step 4: Test

Use wazuh-logtest to verify extraction.

### Step 5: Create Rules

Now create rules that match on the extracted fields.

## Decoder Best Practices

1. **Start with parent decoder**: Define base decoder for program_name
2. **Use child decoders**: Break complex logs into specific patterns
3. **Extract useful fields**: Focus on actionable data
4. **Test thoroughly**: Verify with real log samples
5. **Document regex**: Comment complex patterns
6. **Follow naming convention**: Use descriptive, hierarchical names

## Regular Expression Tips

### Common Patterns

- **IP Address**: `(\d+\.\d+\.\d+\.\d+)`
- **Any word**: `(\S+)`
- **Any text**: `(.+)`
- **Number**: `(\d+)`
- **Date**: `(\d{4}-\d{2}-\d{2})`
- **Time**: `(\d{2}:\d{2}:\d{2})`
- **MAC Address**: `([\da-f]{2}:[\da-f]{2}:[\da-f]{2}:[\da-f]{2}:[\da-f]{2}:[\da-f]{2})`

### Regex Modifiers

- `^`: Start of string
- `$`: End of string
- `.`: Any character
- `*`: Zero or more
- `+`: One or more
- `?`: Zero or one
- `\S`: Non-whitespace
- `\s`: Whitespace
- `\d`: Digit

## Advanced Techniques

### Prematch

Filter logs before applying full regex:

```xml
<decoder name="myapp-error">
  <parent>myapp</parent>
  <prematch>ERROR</prematch>
  <regex>ERROR: (.+)</regex>
  <order>error_message</order>
</decoder>
```

### Offset

Continue matching after parent match:

```xml
<decoder name="myapp-detail">
  <parent>myapp-login</parent>
  <regex offset="after_parent">from port (\d+)</regex>
  <order>srcport</order>
</decoder>
```

### Multiple Decoders for Same Log

Different child decoders can handle variations:

```xml
<decoder name="myapp">
  <program_name>^myapp</program_name>
</decoder>

<decoder name="myapp-login">
  <parent>myapp</parent>
  <prematch>login</prematch>
  <regex>...</regex>
</decoder>

<decoder name="myapp-logout">
  <parent>myapp</parent>
  <prematch>logout</prematch>
  <regex>...</regex>
</decoder>
```

## Installation

1. Copy decoder file:
```bash
sudo cp pfsense_decoders.xml /var/ossec/etc/decoders/
```

2. Set permissions:
```bash
sudo chown wazuh:wazuh /var/ossec/etc/decoders/pfsense_decoders.xml
sudo chmod 640 /var/ossec/etc/decoders/pfsense_decoders.xml
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

### Decoder not matching

1. Check program_name matches log source
2. Verify regex pattern with test tool
3. Check for special characters needing escape
4. Test with actual log samples
5. Review decoder order (parent before child)

### Fields not extracted

1. Verify regex capture groups
2. Check order matches regex groups
3. Test regex separately
4. Look for typos in field names

### Performance issues

1. Use prematch to filter early
2. Avoid overly complex regex
3. Be specific in patterns
4. Consider decoder order

## Debugging

### View decoder processing

```bash
# Enable debug mode
echo "wazuh-analysisd.debug=2" >> /var/ossec/etc/local_internal_options.conf
sudo systemctl restart wazuh-manager

# View debug logs
sudo tail -f /var/ossec/logs/ossec.log | grep decoder
```

### Test specific decoder

```bash
# Test with sample log
echo "your sample log line" | sudo /var/ossec/bin/wazuh-logtest -q
```

## References

- [Wazuh Decoders](https://documentation.wazuh.com/current/user-manual/ruleset/ruleset-xml-syntax/decoders.html)
- [Custom Decoders](https://documentation.wazuh.com/current/user-manual/ruleset/custom.html)
- [Regex Tutorial](https://www.regular-expressions.info/)
