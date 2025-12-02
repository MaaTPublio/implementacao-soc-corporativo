# Solução de Problemas - Lab SOC

## Índice

1. [Problemas Gerais](#problemas-gerais)
2. [Problemas com Wazuh](#problemas-com-wazuh)
3. [Problemas com pfSense](#problemas-com-pfsense)
4. [Problemas de Integração](#problemas-de-integração)
5. [Problemas de Performance](#problemas-de-performance)

## Problemas Gerais

### Sistema está lento

**Sintomas**: Alta utilização de CPU/RAM, interface web lenta

**Soluções**:

1. Verificar recursos do sistema:
```bash
# CPU e RAM
top
htop

# Disco
df -h
du -sh /*
```

2. Verificar logs grandes:
```bash
# Encontrar arquivos grandes
sudo find /var/ossec/logs -type f -size +100M

# Rotacionar logs manualmente se necessário
sudo /var/ossec/bin/wazuh-logrotate
```

3. Ajustar configurações de retenção no Elasticsearch

### Conectividade de rede

**Sintomas**: Componentes não conseguem se comunicar

**Soluções**:

1. Verificar conectividade básica:
```bash
# Ping
ping 192.168.1.10

# Portas
telnet 192.168.1.10 1514
nc -zv 192.168.1.10 1514
```

2. Verificar firewall:
```bash
# Ubuntu/Debian
sudo ufw status
sudo ufw allow from 192.168.1.0/24

# CentOS/RHEL
sudo firewall-cmd --list-all
sudo firewall-cmd --permanent --add-port=1514/tcp
sudo firewall-cmd --reload
```

## Problemas com Wazuh

### Wazuh Manager não inicia

**Sintomas**: Serviço falha ao iniciar

**Diagnóstico**:
```bash
# Verificar status
sudo systemctl status wazuh-manager

# Ver logs de erro
sudo journalctl -u wazuh-manager -n 50

# Verificar configuração
sudo /var/ossec/bin/wazuh-control info
```

**Soluções**:

1. Verificar sintaxe da configuração:
```bash
sudo /var/ossec/bin/verify-agent-conf
```

2. Verificar permissões:
```bash
sudo chown -R wazuh:wazuh /var/ossec
sudo chmod -R 750 /var/ossec
```

3. Verificar espaço em disco:
```bash
df -h /var/ossec
```

### Agentes não conectam

**Sintomas**: Agentes aparecem como "Disconnected" ou "Never connected"

**Diagnóstico**:
```bash
# Listar agentes
sudo /var/ossec/bin/agent_control -l

# Ver detalhes de agente específico
sudo /var/ossec/bin/agent_control -i 001
```

**Soluções**:

1. No agente, verificar configuração:
```bash
# Linux
cat /var/ossec/etc/ossec.conf | grep address

# Windows
type "C:\Program Files (x86)\ossec-agent\ossec.conf" | findstr address
```

2. Verificar conectividade do agente:
```bash
telnet <wazuh-manager-ip> 1514
```

3. Reiniciar agente:
```bash
# Linux
sudo systemctl restart wazuh-agent

# Windows
net stop WazuhSvc
net start WazuhSvc
```

4. Verificar firewall no manager:
```bash
sudo ufw allow 1514/tcp
sudo ufw allow 1515/tcp
```

### Elasticsearch/Indexer está cheio

**Sintomas**: Dashboard não carrega, erro "no space left"

**Soluções**:

1. Verificar uso de disco:
```bash
curl -X GET "localhost:9200/_cat/indices?v"
```

2. Deletar índices antigos:
```bash
# Listar índices
curl -X GET "localhost:9200/_cat/indices?v&s=index"

# Deletar índice específico
curl -X DELETE "localhost:9200/wazuh-alerts-4.x-2023.01.01"
```

3. Configurar ILM (Index Lifecycle Management):
```bash
# Editar política de retenção
curl -X PUT "localhost:9200/_ilm/policy/wazuh-policy" -H 'Content-Type: application/json' -d'
{
  "policy": {
    "phases": {
      "delete": {
        "min_age": "30d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}'
```

### Dashboard não carrega

**Sintomas**: Erro 503, timeout, página em branco

**Diagnóstico**:
```bash
# Verificar serviços
sudo systemctl status wazuh-indexer
sudo systemctl status wazuh-dashboard

# Ver logs
sudo journalctl -u wazuh-dashboard -f
```

**Soluções**:

1. Reiniciar serviços:
```bash
sudo systemctl restart wazuh-indexer
sudo systemctl restart wazuh-dashboard
```

2. Verificar memória disponível:
```bash
free -h
```

3. Ajustar heap do Elasticsearch se necessário:
```bash
sudo nano /etc/wazuh-indexer/jvm.options
# -Xms4g
# -Xmx4g
```

## Problemas com pfSense

### Web interface não acessível

**Sintomas**: Não consegue acessar https://192.168.1.1

**Soluções**:

1. Verificar via console se o serviço está rodando
2. Verificar IP da LAN: Opção 2 no console
3. Resetar para configuração de fábrica se necessário: Opção 4
4. Verificar se navegador aceita certificado auto-assinado

### Regras de firewall não funcionam

**Sintomas**: Tráfego não é bloqueado/permitido como esperado

**Diagnóstico**:

1. Verificar logs do firewall: **Status → System Logs → Firewall**
2. Verificar ordem das regras (primeira match wins)
3. Verificar estados: **Diagnostics → States**

**Soluções**:

1. Revisar ordem das regras
2. Adicionar regra de logging temporária
3. Limpar estados: **Diagnostics → States → Reset States**
4. Verificar NAT se for tráfego de saída

### IDS/IPS não detecta ataques

**Sintomas**: Nenhum alerta do Snort/Suricata

**Soluções**:

1. Verificar se está habilitado e rodando
2. Atualizar regras:
   - **Services → Snort/Suricata → Updates**
   - Atualizar regras e reconstruir database

3. Verificar interface monitorada
4. Verificar configuração de logging

### Logs não são enviados para Wazuh

**Sintomas**: Wazuh não recebe eventos do pfSense

**Diagnóstico**:

1. Verificar configuração: **Status → System Logs → Settings**
2. Testar com logger do sistema

**Soluções**:

1. Verificar IP do servidor syslog
2. Verificar porta (514 UDP)
3. Verificar firewall na LAN (deve permitir para servidor Wazuh)
4. Testar manualmente:
```bash
# No pfSense
logger -p local0.info "Test message"
```

## Problemas de Integração

### Logs do pfSense não aparecem no Wazuh

**Diagnóstico**:
```bash
# Verificar se Wazuh está escutando
sudo netstat -nlpu | grep 514

# Verificar logs do Wazuh
sudo tail -f /var/ossec/logs/ossec.log

# Testar recepção
sudo tcpdump -i any port 514 -A
```

**Soluções**:

1. Verificar configuração de remote em ossec.conf
2. Verificar allowed-ips
3. Reiniciar Wazuh Manager
4. Verificar firewall do servidor Wazuh

### Active Response não bloqueia IPs

**Sintomas**: IPs maliciosos não são bloqueados automaticamente

**Diagnóstico**:
```bash
# Verificar logs de active response
sudo tail -f /var/ossec/logs/active-responses.log

# Verificar configuração
sudo grep -A 10 "active-response" /var/ossec/etc/ossec.conf
```

**Soluções**:

1. Verificar permissões do script:
```bash
sudo chmod 750 /var/ossec/active-response/bin/*.sh
sudo chown root:wazuh /var/ossec/active-response/bin/*.sh
```

2. Testar script manualmente:
```bash
sudo /var/ossec/active-response/bin/firewall-drop add - 1.2.3.4
```

3. Verificar API do pfSense está acessível
4. Verificar credenciais da API

### Decodificadores não funcionam

**Sintomas**: Logs são recebidos mas não são parseados corretamente

**Diagnóstico**:
```bash
# Testar decodificador
sudo /var/ossec/bin/wazuh-logtest

# Inserir log de exemplo e verificar resultado
```

**Soluções**:

1. Verificar sintaxe do decoder
2. Verificar ordem dos decoders (parent/child)
3. Reiniciar Wazuh após modificações
4. Usar logtest para debug

## Problemas de Performance

### Alta utilização de CPU

**Sintomas**: CPU constantemente acima de 80%

**Soluções**:

1. Identificar processo:
```bash
top
ps aux | sort -nrk 3,3 | head -n 5
```

2. Reduzir análise de logs:
   - Desabilitar módulos não utilizados
   - Ajustar frequência de scans (syscheck, rootcheck)

3. Aumentar recursos da VM/servidor

### Alta utilização de memória

**Sintomas**: RAM quase cheia, swap sendo usado

**Soluções**:

1. Ajustar heap do Elasticsearch:
```bash
sudo nano /etc/wazuh-indexer/jvm.options
```

2. Reduzir cache do Wazuh se necessário

3. Adicionar mais RAM ao servidor

### Disco cheio

**Sintomas**: Alertas de disco cheio, serviços falham

**Soluções**:

1. Identificar uso:
```bash
sudo du -sh /var/ossec/* | sort -h
sudo du -sh /var/lib/wazuh-indexer/* | sort -h
```

2. Limpar logs antigos:
```bash
sudo find /var/ossec/logs -name "*.log.*" -mtime +7 -delete
```

3. Configurar rotação de logs adequada

4. Deletar índices antigos do Elasticsearch

## Comandos Úteis

### Wazuh

```bash
# Status de todos componentes
sudo /var/ossec/bin/wazuh-control status

# Reiniciar Wazuh
sudo systemctl restart wazuh-manager

# Ver agentes conectados
sudo /var/ossec/bin/agent_control -l

# Testar regras
sudo /var/ossec/bin/wazuh-logtest

# Ver alertas em tempo real
sudo tail -f /var/ossec/logs/alerts/alerts.log

# Informações do manager
sudo /var/ossec/bin/wazuh-control info
```

### pfSense

```bash
# Reiniciar serviços (via console)
pfSsh.php playback svc restart webConfigurator

# Ver processos
ps aux

# Reiniciar firewall
pfctl -d && pfctl -e

# Ver regras ativas
pfctl -sr
```

## Quando Pedir Ajuda

Se após seguir este guia o problema persistir:

1. Colete informações:
   - Logs relevantes
   - Versões dos softwares
   - Passos para reproduzir o problema
   - Mensagens de erro exatas

2. Consulte documentação oficial:
   - [Wazuh Documentation](https://documentation.wazuh.com/)
   - [pfSense Documentation](https://docs.netgate.com/pfsense/)

3. Comunidades:
   - Wazuh Forum/GitHub Issues
   - pfSense Forum
   - Reddit: r/wazuh, r/PFSENSE

4. Abra uma issue neste repositório com as informações coletadas
