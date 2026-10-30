# Documentação do Protocolo — Nexus

Este diretório armazena a documentação técnica complementar sobre fluxos de mensagens, máquinas de estado do protocolo, negociação de sessão, tratamento de erros e fluxos de segurança (pareamento e autenticação TLS).

---

## Fonte de Verdade dos Schemas

Os schemas formais, exemplos de payloads JSON e regras de evolução de versão residem na pasta raiz [`/protocol`](../../protocol/README.md):

- [`protocol/README.md`](../../protocol/README.md): Envelope padrão, domínios de comandos e regras de versionamento.
- `protocol/schemas/`: Definições formais dos contratos por versão.
- `protocol/examples/`: Payloads de referência consumidos nos testes de compatibilidade entre Kotlin (Android) e Swift (macOS).

Consulte também a [ADR-008 — API de Controle Versionada](../decisions/ADR-008-api-de-controle-versionada.md).

