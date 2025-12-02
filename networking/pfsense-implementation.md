# Implementação de Segurança de Borda (pfSense)

## Configurações de Interface e Segmentação
- **WAN:** Conectada à rede externa, com regras de bloqueio padrão (deny all inbound).
- **LAN:** Rede segregada para ativos protegidos.
- **Gestão:** Acesso HTTPS/SSH permitido apenas via IP de Gestão (Whitelist), bloqueado para o restante da rede.

## Camadas de Proteção

### 1. Detecção de Intrusão (IDS Suricata)
Implementação de inspeção profunda de pacotes (DPI) na interface WAN para visibilidade de ameaças sem interrupção de serviço.

- **Modo de Operação:** IDS (*Intrusion Detection System*). Configurado para **apenas alertar**, garantindo que o tráfego legítimo não seja impactado durante a fase de aprendizado da rede.
- **Rulesets (Assinaturas):**
    - *ETOpen Emerging Threats*
    - *Snort GPLv2 Community Rules*
- **Integração SIEM:** Habilitada a opção *"Send Alerts to System Log"*, permitindo que o Wazuh ingira os alertas de segurança em tempo real via Syslog.
- **Performance & Tuning:** Desativado o *Hardware Offloading* (Checksum, TSO, LRO) nas configurações avançadas do pfSense para garantir que o Suricata capture os pacotes corretamente.

### 2. Bloqueio GeoIP e DNSBL (pfBlockerNG)
- **GeoIP:** Bloqueio de entrada e saída para países de alto risco (Top Spammers).
- **DNS Sinkhole:** Interceptação de consultas DNS para domínios maliciosos.
    - **Ação:** Redirecionamento para VIP `10.10.10.1`.
    - **Validação:** Testes realizados com `nslookup` em domínios de tracking confirmaram o bloqueio.

### 3. Integração SIEM (Wazuh)
Configuração de **Remote Syslog** (UDP 514) enviando:
- Logs de filtro de pacotes (Firewall Events).
- Alertas do Suricata.
- Eventos de sistema e autenticação.
