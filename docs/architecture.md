# Arquitetura do Lab SOC

## Visão Geral da Arquitetura

Este documento descreve a arquitetura do laboratório SOC implementado com Wazuh e pfSense.

## Componentes do Sistema

### 1. pfSense Firewall

**Função**: Gateway de segurança e ponto de entrada da rede

**Características**:
- Interface WAN: Conexão com Internet/rede externa
- Interface LAN: Rede interna protegida
- Interface DMZ (opcional): Zona desmilitarizada para servidores públicos
- IDS/IPS com Snort ou Suricata
- VPN para acesso remoto seguro

**Especificações Mínimas**:
- CPU: 2 cores
- RAM: 4GB
- Disco: 20GB
- Interfaces de rede: 2-3 NICs

### 2. Wazuh Manager

**Função**: Servidor central de monitoramento e análise de segurança

**Componentes**:
- **Wazuh Manager**: Processamento de eventos e correlação
- **Elasticsearch**: Armazenamento de eventos e dados
- **Kibana**: Interface web para visualização e análise
- **Filebeat**: Coleta e envio de logs

**Especificações Mínimas**:
- CPU: 4 cores
- RAM: 8GB (recomendado 16GB)
- Disco: 100GB (SSD recomendado)
- SO: Ubuntu 20.04/22.04 ou CentOS 8

### 3. Wazuh Agents

**Função**: Agentes instalados nos endpoints para coleta de dados

**Capacidades**:
- Monitoramento de integridade de arquivos (FIM)
- Detecção de rootkits
- Análise de logs do sistema
- Detecção de vulnerabilidades
- Resposta ativa a ameaças

## Fluxo de Dados

```
┌──────────────┐
│   Internet   │
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│  pfSense (WAN)   │
│  - Firewall      │
│  - IDS/IPS       │
│  - NAT           │
└──────┬───────────┘
       │
       ▼
┌──────────────────────────────────────┐
│         Rede Interna (LAN)           │
│                                      │
│  ┌────────────┐    ┌──────────────┐ │
│  │   Wazuh    │◄───│   Endpoints  │ │
│  │  Manager   │    │  com Agents  │ │
│  │            │    │              │ │
│  │ ┌────────┐ │    └──────────────┘ │
│  │ │Elastic │ │                     │
│  │ │search  │ │                     │
│  │ └────────┘ │                     │
│  │            │                     │
│  │ ┌────────┐ │                     │
│  │ │Kibana  │◄────────────────────┐ │
│  │ └────────┘ │                   │ │
│  └────────────┘              Analista│
│                              de SOC  │
└──────────────────────────────────────┘
```

## Integração Wazuh-pfSense

### Logs do pfSense para Wazuh

O pfSense envia logs via syslog para o Wazuh Manager:

1. Logs de firewall (bloqueios, permissões)
2. Logs de IDS/IPS (alertas Snort/Suricata)
3. Logs de VPN (conexões, desconexões)
4. Logs de autenticação
5. Logs de sistema

### Resposta Ativa

O Wazuh pode executar ações automatizadas em resposta a eventos:

1. **Bloqueio de IP**: Adicionar regra de bloqueio no pfSense
2. **Isolamento de host**: Quarentena de endpoint comprometido
3. **Alertas**: Notificações para equipe de segurança
4. **Scripts customizados**: Ações personalizadas

## Zonas de Segurança

### Zona Externa (WAN)
- Internet ou rede não confiável
- Tráfego filtrado pelo pfSense
- Políticas restritivas de entrada

### Zona Interna (LAN)
- Rede corporativa protegida
- Workstations e servidores internos
- Monitoramento contínuo com Wazuh agents

### Zona DMZ (opcional)
- Servidores expostos à Internet
- Isolamento adicional da LAN
- Regras de firewall específicas

## Segurança em Camadas

### Camada 1: Perímetro (pfSense)
- Firewall stateful
- IDS/IPS
- VPN
- Filtragem de conteúdo

### Camada 2: Endpoint (Wazuh Agent)
- Monitoramento de integridade
- Detecção de malware
- Análise de comportamento
- Controle de aplicações

### Camada 3: Análise Central (Wazuh Manager)
- Correlação de eventos
- Detecção de ameaças avançadas
- Conformidade regulatória
- Forensics e investigação

## Requisitos de Rede

### Endereçamento IP (Exemplo)

```
WAN:    DHCP ou IP público
LAN:    192.168.1.0/24
DMZ:    192.168.2.0/24
VPN:    10.8.0.0/24

Wazuh Manager: 192.168.1.10
pfSense LAN:   192.168.1.1
```

### Portas Necessárias

**Wazuh**:
- 1514/TCP: Agentes para Manager (eventos)
- 1515/TCP: Agentes para Manager (enrollment)
- 55000/TCP: API REST
- 443/TCP: Kibana web interface

**pfSense**:
- 443/TCP: Web interface (HTTPS)
- 22/TCP: SSH (administração)
- 514/UDP: Syslog
- VPN: 1194/UDP (OpenVPN) ou 500/UDP + 4500/UDP (IPsec)

## Alta Disponibilidade (Opcional)

Para ambientes de produção, considere:

### Wazuh Cluster
- Múltiplos managers em cluster
- Load balancing de agents
- Replicação de dados

### pfSense HA
- CARP (Common Address Redundancy Protocol)
- Config sync entre firewalls
- Failover automático

## Backup e Recuperação

### Wazuh
- Backup diário de configurações
- Snapshot de Elasticsearch
- Backup de regras customizadas

### pfSense
- Backup automático de configuração XML
- Versionamento de configurações
- Procedimento de restauração documentado

## Monitoramento e Métricas

### Métricas de Sistema
- CPU, RAM, Disco
- Throughput de rede
- Latência

### Métricas de Segurança
- Eventos por segundo
- Alertas críticos
- Taxa de falsos positivos
- Tempo de resposta a incidentes

## Referências

- [Wazuh Documentation](https://documentation.wazuh.com/)
- [pfSense Documentation](https://docs.netgate.com/pfsense/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
