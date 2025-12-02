# Wazuh Configuration Files

This directory contains Wazuh Manager configuration files.

## Files

### ossec.conf.example

Complete example configuration file for Wazuh Manager with:
- Global settings
- Remote syslog configuration for pfSense
- Active response configuration
- File integrity monitoring (Syscheck)
- Rootkit detection (Rootcheck)
- Vulnerability detection
- Compliance scanning

**Usage:**

1. Review the example file
2. Copy relevant sections to your `/var/ossec/etc/ossec.conf`
3. Adjust IP addresses and settings for your environment
4. Test configuration: `sudo /var/ossec/bin/wazuh-logtest -t`
5. Restart Wazuh: `sudo systemctl restart wazuh-manager`

## Important Settings

### Remote Syslog Configuration

```xml
<remote>
  <connection>syslog</connection>
  <port>514</port>
  <protocol>udp</protocol>
  <allowed-ips>192.168.1.1</allowed-ips>  <!-- pfSense IP -->
</remote>
```

### Active Response

```xml
<active-response>
  <command>firewall-drop</command>
  <location>local</location>
  <rules_id>100403</rules_id>  <!-- Brute force rule -->
  <timeout>600</timeout>
</active-response>
```

### Email Alerts

```xml
<email_alerts>
  <email_to>your-email@domain.com</email_to>
  <level>10</level>
  <do_not_delay />
</email_alerts>
```

## Configuration Best Practices

1. **Start with defaults**: Don't change everything at once
2. **Test changes**: Use wazuh-logtest to validate
3. **Backup before changes**: `cp ossec.conf ossec.conf.backup`
4. **Monitor logs**: Check `/var/ossec/logs/ossec.log` after changes
5. **Document changes**: Comment your modifications

## Security Considerations

- Keep sensitive information out of version control
- Use appropriate file permissions: `chmod 640 ossec.conf`
- Regularly review and update configurations
- Follow principle of least privilege
- Enable only necessary features

## Troubleshooting

### Configuration won't load

```bash
# Check syntax
sudo /var/ossec/bin/wazuh-logtest -t

# View errors
sudo tail -f /var/ossec/logs/ossec.log
```

### Syslog not receiving

```bash
# Check if port is listening
sudo netstat -ulpn | grep 514

# Test reception
sudo tcpdump -i any port 514 -A
```

## References

- [Wazuh Configuration Reference](https://documentation.wazuh.com/current/user-manual/reference/ossec-conf/)
- [Remote Configuration](https://documentation.wazuh.com/current/user-manual/reference/ossec-conf/remote.html)
- [Active Response](https://documentation.wazuh.com/current/user-manual/capabilities/active-response/)
