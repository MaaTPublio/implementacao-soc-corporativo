# SOAR — Automação de Resposta a Incidentes

Este diretório contém os artefatos do pipeline de automação **Wazuh → Shuffle → pfSense**.

## Arquivos

| Arquivo | Descrição |
|---|---|
| `custom-shuffle-final` | Script bash de integração. Deve ser copiado para `/var/ossec/integrations/` no Wazuh Manager com `chown root:wazuh` e `chmod 750`. |
| `ossec-integration-snippet.xml` | Trecho de configuração para o `ossec.conf`. Contém o bloco `<integration>` e a `<white_list>` de IPs de gestão. |

## Fluxo do Pipeline

```
Wazuh (Nível 10+)
      │
      │  POST JSON via curl -k
      ▼
Shuffle SOAR (Webhook)
      │
      │  Condição: srcip != vazio
      ▼
pfSense (SSH)
      │
      │  /sbin/pfctl -t bloqueio_soar -T add <IP>
      ▼
IP do atacante bloqueado na tabela de memória
```

## Pré-requisitos no pfSense

1. Criar um **Alias** do tipo `Host(s)` com o nome exato `bloqueio_soar` em **Firewall > Aliases**.
2. Criar uma **regra de firewall** referenciando esse alias como origem bloqueada.
3. Garantir que o usuário root do pfSense aceita conexões SSH a partir do IP do Shuffle.

## Simulação de Teste (sem ataque real)

```bash
echo "Apr  8 19:10:00 soc sshd[9999]: Failed password for root from 8.8.8.8 port 1234 ssh2" \
  | sudo tee -a /var/log/auth.log
```

Aguardar ~30s e verificar:

```bash
pfctl -t bloqueio_soar -T show
```
