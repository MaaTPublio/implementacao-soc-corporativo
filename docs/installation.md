# Guia de Instalação do Lab SOC

## Índice

1. [Preparação do Ambiente](#preparação-do-ambiente)
2. [Instalação do pfSense](#instalação-do-pfsense)
3. [Instalação do Wazuh](#instalação-do-wazuh)
4. [Instalação dos Agentes](#instalação-dos-agentes)
5. [Verificação da Instalação](#verificação-da-instalação)

## Preparação do Ambiente

### Requisitos de Hardware

#### Servidor Wazuh Manager
- CPU: 4 cores ou mais
- RAM: 8GB mínimo (16GB recomendado)
- Disco: 100GB+ (SSD recomendado)
- Rede: 1 Gbps NIC

#### pfSense Firewall
- CPU: 2 cores
- RAM: 4GB
- Disco: 20GB
- Rede: 2-3 NICs (WAN, LAN, DMZ opcional)

#### Agentes (por endpoint)
- CPU: Compartilhada
- RAM: 512MB
- Disco: 2GB

### Requisitos de Software

- **Wazuh Manager**: Ubuntu 20.04/22.04 LTS ou CentOS 8
- **pfSense**: Versão 2.6.0 ou superior
- **Agentes**: Windows, Linux, macOS compatíveis

## Instalação do pfSense

### 1. Download do pfSense

```bash
# Baixe a ISO do pfSense
wget https://www.pfsense.org/download/
# Escolha a versão apropriada para sua arquitetura
```

### 2. Instalação Básica

1. Crie uma VM ou boot no hardware dedicado
2. Boot pela ISO do pfSense
3. Selecione "Install"
4. Escolha o disco de destino
5. Aguarde a instalação completar
6. Remova a ISO e reinicie

### 3. Configuração Inicial

**Console Setup**:

```
Enter an option: 1  # Configurar interfaces
WAN interface: em0  (ou sua interface WAN)
LAN interface: em1  (ou sua interface LAN)

Enter an option: 2  # Configurar IP LAN
LAN IP: 192.168.1.1
Subnet: 24
Enable DHCP: yes
DHCP range: 192.168.1.100 - 192.168.1.200
```

### 4. Configuração Web

1. Acesse: `https://192.168.1.1`
2. Login padrão: `admin` / `pfsense`
3. Complete o wizard de configuração:
   - Hostname: `firewall`
   - Domain: `lab.local`
   - DNS: 8.8.8.8, 8.8.4.4
   - Timezone: Seu fuso horário
   - Configure WAN conforme sua rede

### 5. Habilitar Syslog

**System → Advanced → Syslog**:
- Enable Remote Logging: ✓
- Remote Log Servers: `192.168.1.10:514` (IP do Wazuh)
- Remote Syslog Contents: Everything

## Instalação do Wazuh

### 1. Preparação do Sistema

```bash
# Atualizar o sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências
sudo apt install curl apt-transport-https lsb-release gnupg -y
```

### 2. Instalação via Script Automatizado

```bash
# Download e execução do instalador oficial
curl -sO https://packages.wazuh.com/4.7/wazuh-install.sh
sudo bash ./wazuh-install.sh -a
```

O script instalará:
- Wazuh Manager
- Wazuh Indexer (Elasticsearch)
- Wazuh Dashboard (Kibana)
- Filebeat

### 3. Instalação Manual (Alternativa)

#### Wazuh Manager

```bash
# Adicionar repositório
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list

# Atualizar e instalar
sudo apt update
sudo apt install wazuh-manager -y

# Habilitar e iniciar serviço
sudo systemctl daemon-reload
sudo systemctl enable wazuh-manager
sudo systemctl start wazuh-manager
```

#### Wazuh Indexer

```bash
# Instalar Wazuh Indexer
sudo apt install wazuh-indexer -y

# Configurar
sudo /usr/share/wazuh-indexer/bin/indexer-security-init.sh

# Iniciar serviço
sudo systemctl enable wazuh-indexer
sudo systemctl start wazuh-indexer
```

#### Wazuh Dashboard

```bash
# Instalar Dashboard
sudo apt install wazuh-dashboard -y

# Configurar
sudo /usr/share/wazuh-dashboard/bin/opensearch-dashboards-plugin list

# Iniciar serviço
sudo systemctl enable wazuh-dashboard
sudo systemctl start wazuh-dashboard
```

### 4. Configuração Inicial do Wazuh

#### Habilitar Recepção de Syslog

Edite `/var/ossec/etc/ossec.conf`:

```xml
<ossec_config>
  <remote>
    <connection>syslog</connection>
    <port>514</port>
    <protocol>udp</protocol>
    <allowed-ips>192.168.1.0/24</allowed-ips>
  </remote>
</ossec_config>
```

Reinicie o Wazuh:

```bash
sudo systemctl restart wazuh-manager
```

### 5. Acessar Wazuh Dashboard

1. Acesse: `https://<wazuh-ip>` (padrão: porta 443)
2. Credenciais padrão estão no arquivo:
   ```bash
   sudo cat /usr/share/wazuh-indexer/opensearch-security/internal_users.yml
   ```
3. Usuário padrão: `admin`
4. Senha: (verificar no arquivo de instalação)

## Instalação dos Agentes

### Linux (Ubuntu/Debian)

```bash
# Adicionar repositório
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg

echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee -a /etc/apt/sources.list.d/wazuh.list

# Instalar agente
sudo apt update
sudo apt install wazuh-agent -y

# Configurar Manager
echo "WAZUH_MANAGER='192.168.1.10'" >> /var/ossec/etc/ossec.conf

# Iniciar agente
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent
```

### Windows

1. Baixe o instalador: `https://packages.wazuh.com/4.x/windows/wazuh-agent-4.x.x-1.msi`
2. Execute o instalador
3. Configure o endereço do Manager: `192.168.1.10`
4. Complete a instalação

### macOS

```bash
# Download do pacote
curl -O https://packages.wazuh.com/4.x/macos/wazuh-agent-4.x.x-1.pkg

# Instalar
sudo installer -pkg wazuh-agent-4.x.x-1.pkg -target /

# Configurar Manager
sudo /Library/Ossec/bin/agent-auth -m 192.168.1.10

# Iniciar agente
sudo /Library/Ossec/bin/wazuh-control start
```

## Verificação da Instalação

### Verificar Wazuh Manager

```bash
# Status do serviço
sudo systemctl status wazuh-manager

# Verificar conectividade de agentes
sudo /var/ossec/bin/agent_control -l

# Verificar logs
sudo tail -f /var/ossec/logs/ossec.log
```

### Verificar pfSense

1. Acesse o Dashboard web
2. Verifique Status → Interfaces
3. Verifique Status → System Logs → Firewall

### Verificar Agentes

```bash
# Linux
sudo systemctl status wazuh-agent

# Verificar conectividade
sudo /var/ossec/bin/agent_control -i <agent-id>
```

### Verificar Integração

No Wazuh Dashboard:
1. Navegue para "Agents"
2. Verifique se todos os agentes aparecem como "Active"
3. Navegue para "Modules" → "Security Events"
4. Verifique se eventos do pfSense estão sendo recebidos

## Troubleshooting

### Agente não conecta

```bash
# Verificar configuração
cat /var/ossec/etc/ossec.conf | grep address

# Testar conectividade
telnet 192.168.1.10 1514

# Verificar firewall
sudo ufw status
sudo ufw allow 1514/tcp
sudo ufw allow 1515/tcp
```

### pfSense não envia logs

1. Verifique configuração de syslog no pfSense
2. Teste conectividade: `telnet 192.168.1.10 514`
3. Verifique regras de firewall (liberar porta 514/UDP)

### Wazuh Dashboard não carrega

```bash
# Verificar serviços
sudo systemctl status wazuh-indexer
sudo systemctl status wazuh-dashboard

# Verificar logs
sudo journalctl -u wazuh-dashboard -f
```

## Próximos Passos

Após a instalação, consulte:
- [Integração Wazuh-pfSense](integration.md)
- [Configuração de Regras Customizadas](../wazuh/rules/README.md)
- [Dashboards e Alertas](../monitoring/README.md)

## Referências

- [Wazuh Installation Guide](https://documentation.wazuh.com/current/installation-guide/)
- [pfSense Installation Guide](https://docs.netgate.com/pfsense/en/latest/install/)
