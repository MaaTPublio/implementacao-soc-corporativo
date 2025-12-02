# Implementação de Lab SOC: Monitoramento e Defesa Ativa

## 📋 Visão Geral

Este projeto implementa um laboratório completo de Security Operations Center (SOC) utilizando Wazuh para monitoramento de segurança e pfSense para defesa ativa de perímetro de rede.

## 🎯 Objetivos

- Implementar um ambiente de monitoramento de segurança centralizado
- Configurar defesa ativa através de firewall pfSense
- Integrar Wazuh com pfSense para resposta automatizada a incidentes
- Estabelecer práticas de detecção e resposta a ameaças

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                    Internet/Rede Externa                     │
└───────────────────────────┬─────────────────────────────────┘
                            │
                    ┌───────▼────────┐
                    │   pfSense      │
                    │   Firewall     │
                    └───────┬────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
┌───────▼────────┐  ┌──────▼───────┐  ┌────────▼────────┐
│ Wazuh Manager  │  │   Endpoints  │  │  Demilitarized  │
│   (Server)     │  │  Monitorados │  │      Zone       │
└────────────────┘  └──────────────┘  └─────────────────┘
```

## 📁 Estrutura do Projeto

```
implementacao-lab-soc/
├── docs/                    # Documentação detalhada
│   ├── architecture.md      # Arquitetura do sistema
│   ├── installation.md      # Guia de instalação
│   ├── integration.md       # Integração Wazuh-pfSense
│   └── troubleshooting.md   # Solução de problemas
├── wazuh/                   # Configurações do Wazuh
│   ├── config/              # Arquivos de configuração
│   ├── rules/               # Regras customizadas
│   ├── decoders/            # Decodificadores personalizados
│   └── scripts/             # Scripts de automação
├── pfsense/                 # Configurações do pfSense
│   ├── config/              # Configurações XML
│   ├── rules/               # Regras de firewall
│   └── scripts/             # Scripts de configuração
├── scripts/                 # Scripts de instalação e setup
│   ├── install-wazuh.sh     # Instalação do Wazuh
│   ├── install-pfsense.sh   # Configuração do pfSense
│   └── integrate.sh         # Script de integração
├── monitoring/              # Dashboards e alertas
│   ├── dashboards/          # Dashboards do Kibana
│   └── alerts/              # Configurações de alertas
└── examples/                # Exemplos de configuração
```

## 🚀 Início Rápido

### Pré-requisitos

- Sistema operacional: Ubuntu Server 20.04+ ou CentOS 8+
- Memória RAM: Mínimo 8GB (recomendado 16GB)
- Disco: Mínimo 50GB
- Rede: Interface de rede configurada
- pfSense: Versão 2.6.0 ou superior
- Wazuh: Versão 4.x

### Instalação Básica

1. Clone o repositório:
```bash
git clone https://github.com/MaaTPublio/implementacao-lab-soc.git
cd implementacao-lab-soc
```

2. Execute o script de instalação do Wazuh:
```bash
sudo ./scripts/install-wazuh.sh
```

3. Configure o pfSense seguindo o guia em `docs/installation.md`

4. Integre os sistemas:
```bash
sudo ./scripts/integrate.sh
```

## 📚 Documentação

Para informações detalhadas, consulte:

- [Arquitetura do Sistema](docs/architecture.md)
- [Guia de Instalação Completo](docs/installation.md)
- [Integração Wazuh-pfSense](docs/integration.md)
- [Solução de Problemas](docs/troubleshooting.md)

## 🔧 Componentes Principais

### Wazuh

Wazuh é uma plataforma de segurança open-source que fornece:
- Detecção de intrusões (IDS)
- Monitoramento de integridade de arquivos
- Análise de vulnerabilidades
- Resposta a incidentes
- Conformidade regulatória (PCI DSS, GDPR, HIPAA)

### pfSense

pfSense é uma distribuição de firewall/router baseada em FreeBSD que oferece:
- Firewall stateful
- VPN (IPsec, OpenVPN)
- Balanceamento de carga
- Filtragem de pacotes
- IDS/IPS (com Snort/Suricata)

## 🔐 Segurança

Este projeto implementa as seguintes práticas de segurança:

- Autenticação multi-fator (MFA)
- Criptografia de comunicações
- Segregação de rede
- Princípio do menor privilégio
- Logging centralizado
- Backup automático de configurações

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Faça fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/NovaFuncionalidade`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/NovaFuncionalidade`)
5. Abra um Pull Request

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 📞 Suporte

Para questões e suporte:
- Abra uma issue no GitHub
- Consulte a documentação em `docs/`
- Verifique problemas conhecidos em `docs/troubleshooting.md`

## 🙏 Agradecimentos

- Comunidade Wazuh
- Comunidade pfSense
- Contribuidores do projeto

## 📊 Status do Projeto

- ✅ Estrutura inicial do projeto
- 🚧 Configurações do Wazuh
- 🚧 Configurações do pfSense
- 🚧 Scripts de integração
- 🚧 Documentação completa
- 📋 Dashboards e alertas

---

**Nota**: Este é um projeto educacional/laboratorial. Para ambientes de produção, realize avaliações de segurança adicionais e ajustes conforme necessário.
