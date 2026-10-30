# Arquitetura do Sistema — Nexus

Este diretório reúne a documentação arquitetural detalhada do **Nexus**, cobrindo a comunicação entre os clientes nativos **Android** e **macOS**, a modelagem de domínio e a separação dos planos de transporte.

---

## 1. Visão Geral dos Subsistemas

| Subsistema | Responsabilidade Principal |
|---|---|
| **Device Hub** | Descoberta mDNS/DNS-SD, pareamento autenticado, gestão de chaves de confiança, máquina de estados da sessão, heartbeat e reconexão automática. |
| **Camera Hub** | Captura avançada via `Camera2`, codificação H.264 por hardware (`MediaCodec`), streaming WebRTC e controles manuais baseados nas capacidades reais do sensor. |
| **Screen Hub** | Captura de tela via `MediaProjection`, streaming WebRTC, mapeamento de coordenadas e controle remoto autorizado via `AccessibilityService`. |
| **File Hub** | Transferência bidirecional de arquivos em blocos sobre TCP/TLS com verificação de integridade SHA-256 e histórico local. |
| **Clipboard Hub** | Sincronização segura de texto da área de transferência com consentimento explícito e prevenção de loops. |

---

## 2. Separação dos Três Planos Lógicos

- **Plano de Controle (TLS):** Autenticação, pareamento, negociação de sessão, comandos e sinalização WebRTC.
- **Plano de Mídia (WebRTC / DTLS-SRTP):** Transmissão de vídeo de baixa latência (câmera e espelhamento de tela).
- **Plano de Dados (TCP/TLS):** Transferência confiável de arquivos e área de transferência sem bloquear o pipeline de vídeo.

---

## 3. Referências Rápidas

- [Especificação Completa do Produto e Arquitetura (`README.md`)](../../README.md)
- [Decisões Arquiteturais — ADRs (`docs/decisions/`)](../decisions/README.md)
- [Especificação e Convenções do Protocolo (`protocol/`)](../../protocol/README.md)
- [Estratégia de Testes e Qualidade (`docs/testing/`)](../testing/README.md)

