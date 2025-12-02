# Integração Wazuh-pfSense

## Visão Geral

Este guia descreve como integrar o Wazuh Manager com o pfSense para criar um sistema completo de monitoramento e resposta a incidentes de segurança.

## Objetivos da Integração

1. Receber e analisar logs do pfSense no Wazuh
2. Detectar ameaças através de análise de firewall e IDS/IPS
3. Implementar resposta ativa para bloqueio automático de IPs maliciosos
4. Criar visualizações e dashboards unificados
5. Correlacionar eventos de firewall com atividade de endpoints

## Parte 1: Configurar pfSense para Enviar Logs

### 1.1 Configurar Remote Logging

No pfSense Web Interface:

1. Navegue para **Status → System Logs → Settings**
2. Na seção **Remote Logging Options**:
   - ✓ Enable Remote Logging
   - Remote log servers: `192.168.1.10:514` (IP do Wazuh Manager)
   - Remote Syslog Contents: Selecione todos relevantes:
     - ✓ Everything
     - ✓ Firewall Events
     - ✓ DHCP Events
     - ✓ VPN Events
     - ✓ Portal Auth
     - ✓ Resolver Events
     - ✓ Wireless Events

3. Clique em **Save**

### 1.2 Configurar IDS/IPS Logging (Snort/Suricata)

Se estiver usando Snort ou Suricata:

**Para Snort:**
1. Navegue para **Services → Snort → Snort Interfaces**
2. Edite a interface
3. Na aba "Logging Settings":
   - ✓ Send Alerts to System Log
   - ✓ Enable Packet Logging

**Para Suricata:**
1. Navegue para **Services → Suricata → Interfaces**
2. Edite a interface
3. Em "EVE Output Settings":
   - ✓ EVE JSON Log
   - ✓ Enable Syslog Output

## Parte 2: Configurar Wazuh para Receber Logs do pfSense

### 2.1 Habilitar Recepção de Syslog

Edite o arquivo de configuração do Wazuh Manager:

```bash
sudo nano /var/ossec/etc/ossec.conf
```

Adicione a seção de remote syslog:

```xml
<ossec_config>
  <remote>
    <connection>syslog</connection>
    <port>514</port>
    <protocol>udp</protocol>
    <allowed-ips>192.168.1.1</allowed-ips>
  </remote>

  <remote>
    <connection>secure</connection>
    <port>1514</port>
    <protocol>tcp</protocol>
    <queue_size>131072</queue_size>
  </remote>
</ossec_config>
```

### 2.2 Criar Decodificadores para pfSense

Crie o arquivo de decodificadores customizados:

```bash
sudo nano /var/ossec/etc/decoders/pfsense_decoders.xml
```

Adicione os decodificadores (exemplo no arquivo `wazuh/decoders/pfsense_decoders.xml`).

### 2.3 Criar Regras para pfSense

Crie o arquivo de regras customizadas:

```bash
sudo nano /var/ossec/etc/rules/pfsense_rules.xml
```

Adicione as regras (exemplo no arquivo `wazuh/rules/pfsense_rules.xml`).

### 2.4 Verificar Configuração

```bash
# Testar configuração
sudo /var/ossec/bin/wazuh-logtest

# Reiniciar Wazuh
sudo systemctl restart wazuh-manager

# Verificar logs
sudo tail -f /var/ossec/logs/ossec.log
```

## Parte 3: Resposta Ativa

### 3.1 Configurar Active Response no Wazuh

Edite `/var/ossec/etc/ossec.conf`:

```xml
<ossec_config>
  <command>
    <name>firewall-drop</name>
    <executable>firewall-drop</executable>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <active-response>
    <command>firewall-drop</command>
    <location>local</location>
    <rules_id>100200,100201</rules_id>
    <timeout>600</timeout>
  </active-response>
</ossec_config>
```

### 3.2 Script de Bloqueio no pfSense

Crie um script para adicionar regras de bloqueio via API do pfSense:

```bash
sudo nano /var/ossec/active-response/bin/pfsense-block.sh
```

Conteúdo (ver arquivo `pfsense/scripts/block-ip.sh`).

### 3.3 Testar Active Response

```bash
# Simular evento de ataque
sudo /var/ossec/bin/agent_control -b <ip_malicioso>

# Verificar logs de active response
sudo tail -f /var/ossec/logs/active-responses.log
```

## Parte 4: Configurar API do pfSense

### 4.1 Instalar pacote pfSense API

No pfSense:

1. Navegue para **System → Package Manager → Available Packages**
2. Procure por "pfSense-pkg-API"
3. Clique em "Install"

### 4.2 Configurar API

1. Navegue para **System → API**
2. Crie uma nova API key:
   - Username: `wazuh-api`
   - Permissions: Firewall rules (read/write)
   - Generate API Key e Secret

3. Salve as credenciais de forma segura

### 4.3 Testar API

```bash
# Exemplo de teste da API
curl -k -u "wazuh-api:API_SECRET" \
  "https://192.168.1.1/api/v1/firewall/rule"
```

## Parte 5: Dashboards e Visualizações

### 5.1 Importar Dashboard do pfSense

No Wazuh Dashboard:

1. Navegue para **Wazuh → Management → Configuration**
2. Importe os dashboards do pfSense (ver `monitoring/dashboards/`)

### 5.2 Criar Visualizações Customizadas

Exemplos de visualizações úteis:

1. **Top 10 IPs Bloqueados**
2. **Timeline de Eventos de Firewall**
3. **Mapa de Geo-localização de Ataques**
4. **Alertas IDS/IPS por Severidade**
5. **Tentativas de Conexão VPN**

## Parte 6: Casos de Uso

### 6.1 Detecção de Brute Force

Regra para detectar múltiplas tentativas de login SSH:

```xml
<rule id="100300" level="10">
  <if_sid>5551</if_sid>
  <description>Multiple SSH failed login attempts from same source</description>
  <same_source_ip />
  <frequency>5</frequency>
  <timeframe>300</timeframe>
</rule>
```

### 6.2 Detecção de Port Scanning

```xml
<rule id="100301" level="8">
  <if_sid>4001</if_sid>
  <description>Possible port scan detected</description>
  <same_source_ip />
  <frequency>10</frequency>
  <timeframe>60</timeframe>
</rule>
```

### 6.3 Bloqueio de IP Automatizado

Quando as regras acima dispararem, o Active Response bloqueará automaticamente o IP no pfSense.

## Parte 7: Monitoramento e Manutenção

### 7.1 Verificações Diárias

```bash
# Verificar status dos serviços
sudo systemctl status wazuh-manager
sudo systemctl status wazuh-indexer

# Verificar eventos recentes
sudo tail -100 /var/ossec/logs/alerts/alerts.log

# Verificar active responses
sudo tail -100 /var/ossec/logs/active-responses.log
```

### 7.2 Análise de Logs do pfSense

No Wazuh Dashboard:
1. Navegue para **Discover**
2. Filtro: `agent.name:pfsense` ou `data.srcip:*`
3. Analise padrões e anomalias

### 7.3 Tuning de Regras

- Ajuste níveis de severidade conforme necessário
- Reduza falsos positivos através de exceções
- Adicione whitelists para IPs confiáveis

## Parte 8: Backup e Recuperação

### 8.1 Backup de Configurações

```bash
# Backup Wazuh
sudo tar -czf wazuh-backup-$(date +%Y%m%d).tar.gz \
  /var/ossec/etc/ossec.conf \
  /var/ossec/etc/rules/*.xml \
  /var/ossec/etc/decoders/*.xml

# Backup pfSense via Web Interface
# Diagnostics → Backup & Restore → Backup Configuration
```

### 8.2 Restauração

```bash
# Restaurar configurações do Wazuh
sudo tar -xzf wazuh-backup-YYYYMMDD.tar.gz -C /

# Reiniciar serviço
sudo systemctl restart wazuh-manager
```

## Troubleshooting

### Logs não chegam do pfSense

1. Verificar conectividade:
   ```bash
   nc -u -l 514  # No servidor Wazuh
   ```

2. No pfSense, teste syslog:
   ```bash
   logger -p local0.info "Test message from pfSense"
   ```

3. Verificar firewall:
   ```bash
   sudo ufw allow 514/udp
   ```

### Active Response não funciona

1. Verificar permissões:
   ```bash
   sudo chmod 750 /var/ossec/active-response/bin/pfsense-block.sh
   sudo chown root:wazuh /var/ossec/active-response/bin/pfsense-block.sh
   ```

2. Verificar logs:
   ```bash
   sudo tail -f /var/ossec/logs/active-responses.log
   ```

### API do pfSense não responde

1. Verificar se o pacote está instalado
2. Verificar credenciais da API
3. Testar com curl manualmente
4. Verificar regras de firewall (porta 443)

## Referências

- [Wazuh pfSense Integration](https://documentation.wazuh.com/current/proof-of-concept-guide/poc-integrate-pfsense.html)
- [pfSense API Documentation](https://docs.netgate.com/pfsense/en/latest/api/)
- [Wazuh Active Response](https://documentation.wazuh.com/current/user-manual/capabilities/active-response/)

## Próximos Passos

- Explore regras customizadas em `wazuh/rules/`
- Configure alertas personalizados
- Implemente playbooks de resposta a incidentes
- Integre com ferramentas de ticketing (OTRS, Jira, etc.)
