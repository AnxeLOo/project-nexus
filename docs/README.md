# Documentação Técnica — Projeto Nexus

Bem-vindo ao diretório central de documentação técnica do **Nexus** — Hub de Integração Nativa entre Android e macOS.

Toda a especificação original de produto, arquitetura, protocolo, modelagem de dados, qualidade e roadmap está organizada modularmente nos documentos abaixo.

---

## 1. Produto e Planejamento

- [**Visão Geral do Produto e Premissas Técnicas (`product-overview.md`)**](./product-overview.md)
  - Proposta de valor, problemas resolvidos, público-alvo, os 5 subsistemas (`Screen Hub`, `Camera Hub`, `File Hub`, `Clipboard Hub`, `Device Hub`), modos de conectividade e premissas técnicas (`AccessibilityService`, `CoreMediaIO`, `Camera2`).
- [**Roadmap e Priorização (`roadmap.md`)**](./roadmap.md)
  - As 3 fases do projeto (Fundação/Conectividade, Streaming/Controle Remoto e Webcam Virtual/Distribuição) e matriz de priorização `P0`–`P3`.
- [**Recomendação para a Primeira Implementação (`recomendation.md`)**](./recomendation.md)
  - Escopo do experimento técnico inicial de redução de riscos.
- [**Configuração do Product Backlog (`backlog-setup.md`)**](./backlog-setup.md)
  - Épicos, labels, milestones e automação para GitHub Projects.

---

## 2. Arquitetura e Engenharia

- [**Arquitetura do Sistema — Alta Visão (`architecture/README.md`)**](./architecture/README.md)
  - Subsistemas, separação dos 3 planos lógicos (Controle, Mídia e Dados), diagrama ponta a ponta, estrutura do monorepo e pilares arquiteturais.
- [**Modelagem de Entidades e Domínio (`architecture/data-model.md`)**](./architecture/data-model.md)
  - Entidades persistentes (`Room`), modelos de domínio puros e árvore de relacionamentos.
- [**Componentes Críticos e Pipelines (`architecture/components-and-pipelines.md`)**](./architecture/components-and-pipelines.md)
  - Pipeline de câmera (`Camera2` vs `CameraX`, H.264, metas de latência), espelhamento (`MediaProjection`), mapeamento de entrada, túnel de rede local e extensão `CoreMediaIO`.
- [**Arquitetura Android, Modularização e Concorrência (`architecture/android-architecture.md`)**](./architecture/android-architecture.md)
  - Camadas Clean Architecture + MVVM, módulos Gradle, escopos de Coroutines e máquina de estados de conexão/reconexão.
- [**Architecture Decision Records — ADRs (`decisions/README.md`)**](./decisions/README.md)
  - Índice completo das 10 decisões arquiteturais (`ADR-001` a `ADR-010`).

---

## 3. Protocolo, Qualidade e Operações

- [**Estratégia de Comunicação e Protocolo (`protocol/README.md`)**](./protocol/README.md)
  - Origem da API privada, fluxo de pareamento mDNS/TLS, contrato de mensagens e referência para os schemas canônicos em [`/protocol`](../protocol/README.md).
- [**Estratégia de Testes e Qualidade (`testing/README.md`)**](./testing/README.md)
  - Testes unitários, testes de integração, fluxos de UI e métricas de desempenho.
- [**Build, CI/CD e Execução Local (`build-and-release.md`)**](./build-and-release.md)
  - Variantes de build (`debug`/`release`), pipeline de CI/CD e comandos de compilação.

---

## 4. Protótipos Interativos de Interface (`prototypes/`)

| Plataforma | Tela | Arquivo |
|---|---|---|
| **macOS** | Dashboard Principal & Preview | [`prototypes/macos/home.html`](./prototypes/macos/home.html) |
| **Android** | Dashboard Material You | [`prototypes/android/home.html`](./prototypes/android/home.html) |
| **Android** | Transferências de Arquivos | [`prototypes/android/transfers.html`](./prototypes/android/transfers.html) |
| **Android** | Gestão de Dispositivos | [`prototypes/android/devices.html`](./prototypes/android/devices.html) |
| **Android** | Configurações Globais | [`prototypes/android/config.html`](./prototypes/android/config.html) |

---

## 5. Documentação dos Clientes

- [**Nexus Android (`android/README.md`)**](../android/README.md)
- [**Nexus Desktop macOS (`macos/README.md`)**](../macos/README.md)
- [**Especificação Canônica do Protocolo (`protocol/README.md`)**](../protocol/README.md)

