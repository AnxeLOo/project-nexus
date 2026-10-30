# Arquitetura do Sistema — Nexus

> Este documento consolida a visão arquitetural central do **Nexus**, integrando a **Seção 5.1 (Diagrama de comunicação)**, a **Seção 8.1 (Organização do repositório)** e a **Seção 15 (Conclusão e recomendação técnica)** da especificação original.

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

## 3. Diagrama de Comunicação (Alta Visão)

```text
┌──────────────────────────────────┐
│            ANDROID               │
│                                  │
│  Nexus App                       │
│  ┌────────────────────────────┐  │
│  │ UI / ViewModels            │  │
│  └─────────────┬──────────────┘  │
│                │                 │
│  ┌─────────────▼──────────────┐  │
│  │ Domain                     │  │
│  │ Use Cases / Policies       │  │
│  └─────────────┬──────────────┘  │
│                │                 │
│  ┌─────────────▼──────────────┐  │
│  │ Data / Device Services     │  │
│  │                            │  │
│  │ Room | Pairing | Network   │  │
│  │ Camera2 | MediaProjection  │  │
│  │ Video Encoder              │  │
│  └─────────────┬──────────────┘  │
└────────────────┼─────────────────┘
                 │
      USB / Wi-Fi / LAN
                 │
     ┌───────────▼───────────┐
     │ TRANSPORT LAYER       │
     │                       │
     │ Control: TLS          │
     │ Media: WebRTC         │
     │ Files: TCP/TLS        │
     │ Discovery: mDNS       │
     └───────────┬───────────┘
                 │
┌────────────────▼─────────────────┐
│              macOS               │
│                                  │
│  Nexus Desktop                   │
│  ┌────────────────────────────┐  │
│  │ SwiftUI / View Models      │  │
│  └─────────────┬──────────────┘  │
│                │                 │
│  ┌─────────────▼──────────────┐  │
│  │ Connection & Session Core  │  │
│  │ Video Receiver             │  │
│  │ Input Mapping              │  │
│  │ File / Clipboard Services  │  │
│  └─────────────┬──────────────┘  │
│                │                 │
│  ┌─────────────▼──────────────┐  │
│  │ Native macOS Integration   │  │
│  │ AVFoundation               │  │
│  │ CoreMediaIO Extension      │  │
│  │ File System                │  │
│  └────────────────────────────┘  │
└──────────────────────────────────┘
```

O diagrama representa uma arquitetura lógica. No produto final, o Nexus Desktop poderá separar a interface gráfica, o processo de conexão e a extensão de câmera em componentes executáveis distintos.

---

## 4. Organização do Repositório (Monorepo)

Recomendo começar com um monorepositório para facilitar a evolução do protocolo e a integração entre os dois clientes.

```text
nexus/
├── android/
│   ├── app/
│   ├── core/
│   ├── feature/
│   └── platform/
│
├── macos/
│   ├── NexusApp/
│   ├── NexusCore/
│   ├── NexusCameraExtension/
│   └── NexusTests/
│
├── protocol/
│   ├── schemas/
│   ├── examples/
│   └── README.md
│
├── docs/
│   ├── architecture/
│   ├── decisions/
│   ├── protocol/
│   ├── prototypes/
│   └── testing/
│
├── scripts/
├── .github/
│   └── workflows/
└── README.md
```

O monorepositório permite versionar o protocolo junto aos clientes, testar mudanças de contrato em conjunto e manter documentação técnica centralizada.

A pasta `protocol` deve ser independente das implementações específicas de Kotlin e Swift. Os schemas serão a fonte de verdade para as mensagens compartilhadas.

---

## 5. Conclusão e Pilares Arquiteturais

O Nexus deve ser tratado como uma plataforma de integração entre dispositivos, e não simplesmente como um aplicativo Android que transmite vídeo.

O produto depende da colaboração entre duas implementações nativas, um protocolo versionado, serviços de infraestrutura e integrações específicas de cada sistema operacional.

A arquitetura proposta tem cinco pilares:

1. **Android nativo com Kotlin:** responsável pela captura, pelos controles do dispositivo e pela interface móvel.
2. **Clean Architecture + MVVM:** responsável pela separação das regras de negócio, da persistência e da interface.
3. **WebRTC:** responsável pelo transporte de mídia em tempo real e, quando apropriado, por canais de dados.
4. **Cliente macOS nativo em Swift:** responsável pelo recebimento dos streams, pela experiência desktop e pela integração com recursos do sistema.
5. **Protocolo próprio e seguro:** responsável pelo pareamento, pelos comandos, pelo gerenciamento das sessões e pela compatibilidade entre as plataformas.

---

## 6. Documentos Detalhados de Arquitetura

- [Modelagem de Entidades e Domínio (`docs/architecture/data-model.md`)](./data-model.md)
- [Modelagem dos Componentes Críticos e Pipelines (`docs/architecture/components-and-pipelines.md`)](./components-and-pipelines.md)
- [Arquitetura Android, Modularização e Concorrência (`docs/architecture/android-architecture.md`)](./android-architecture.md)
- [Decisões Arquiteturais — ADRs (`docs/decisions/`)](../decisions/README.md)
- [Estratégia e Especificação do Protocolo (`docs/protocol/`)](../protocol/README.md)
- [Estratégia de Testes e Qualidade (`docs/testing/`)](../testing/README.md)
