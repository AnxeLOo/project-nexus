# Architecture Decision Records (ADRs) — Nexus

Este diretório registra as **Decisões Arquiteturais (ADRs)** que fundamentam o design, as escolhas tecnológicas e os limites dos subsistemas do **Nexus** (Hub de Integração entre Android e macOS).

---

## Índice de Decisões

| ID | Título | Status | Resumo da Justificativa |
|---|---|---|---|
| [ADR-001](./ADR-001-monorepositorio-inicial.md) | Monorepositório inicial | Aceito | Facilita a evolução atômica e conjunta dos clientes Android, macOS e do contrato de protocolo. |
| [ADR-002](./ADR-002-clean-architecture-mvvm.md) | Clean Architecture + MVVM | Aceito | Separa regras de negócio, interface e infraestrutura, mantendo o domínio independente de frameworks. |
| [ADR-003](./ADR-003-webrtc-para-midia.md) | WebRTC para mídia | Aceito | Evita implementar do zero um protocolo de streaming em tempo real e aproveita controle de congestionamento maduro. |
| [ADR-004](./ADR-004-camera2-para-controles-avancados.md) | Camera2 para controles avançados | Aceito | Oferece acesso direto aos parâmetros manuais suportados pelo hardware (ISO, exposição, zoom) e `Surface` de encoder. |
| [ADR-005](./ADR-005-tcp-tls-para-arquivos.md) | TCP/TLS para arquivos | Aceito | Simplifica confiabilidade, ordenação, controle de fluxo, integridade SHA-256 e recuperação de falhas. |
| [ADR-006](./ADR-006-room-para-dados-locais.md) | Room para dados locais | Aceito | Mantém configurações, dispositivos pareados, perfis de câmera e histórico disponíveis entre execuções. |
| [ADR-007](./ADR-007-extensao-coremediaio-independente.md) | Extensão CoreMediaIO independente | Aceito | Isola a integração de câmera virtual no macOS da visualização direta de vídeo no cliente desktop. |
| [ADR-008](./ADR-008-api-de-controle-versionada.md) | API de controle versionada | Aceito | Permite evoluir os clientes Android e macOS sem quebrar contratos de mensagens silenciosamente. |
| [ADR-009](./ADR-009-sem-servidor-de-midia-obrigatorio.md) | Sem servidor de mídia obrigatório | Aceito | Prioriza comunicação direta na rede local (LAN/USB), baixa latência e privacidade sem dependência de nuvem. |
| [ADR-010](./ADR-010-controle-remoto-permissoes-explicitas.md) | Controle remoto baseado em permissões explícitas | Aceito | Respeita o modelo de segurança do Android utilizando `AccessibilityService` autorizado pelo usuário. |

---

## Formato Padrão de ADR

Cada documento ADR neste diretório segue a estrutura:

1. **Status:** Proposto | Aceito | Substituído | Depreciado
2. **Contexto:** O problema técnico, as forças em jogo e as restrições de plataforma.
3. **Decisão:** A abordagem arquitetural escolhida.
4. **Consequências:** Impactos positivos, trade-offs e requisitos de implementação decorrentes da decisão.

