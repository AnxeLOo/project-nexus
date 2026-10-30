# Nexus Desktop (macOS)

Cliente e daemon nativo para **macOS** desenvolvido em **Swift** e **SwiftUI**, responsável por anunciar e descobrir dispositivos na rede local, gerenciar sessões autenticadas, receber e renderizar streams de vídeo de baixa latência (câmera e tela), mapear eventos de entrada (mouse, trackpad e teclado), gerenciar transferências de arquivos/clipboard e disponibilizar o vídeo como webcam virtual via `CoreMediaIO`.

---

## 1. Organização de Módulos

```text
macos/
├── NexusApp/                 # Interface gráfica nativa em SwiftUI, ViewModels e janelas de preview
├── NexusCore/                # Domínio, máquina de estados da sessão, protocolo, mDNS, TLS e WebRTC
├── NexusCameraExtension/     # Extensão de câmera virtual baseada em CoreMediaIO (Fase 3)
└── NexusTests/               # Testes unitários e de integração do cliente macOS
```

### Responsabilidades

| Módulo | Responsabilidade |
|---|---|
| `NexusApp` | Camada de apresentação em SwiftUI, gerenciamento de janelas, preview de vídeo (`AVFoundation`/`Metal`) e captura de eventos de entrada. |
| `NexusCore` | Camada independente de UI contendo modelos de domínio, serialização do protocolo (`Codable`), descoberta Bonjour/mDNS (`Network.framework`), transporte seguro (`TLS`), receptor `WebRTC` e serviços de arquivos/clipboard. |
| `NexusCameraExtension` | System Extension isolada baseada em `CoreMediaIO` responsável por expor o stream recebido como câmera virtual selecionável em apps de terceiros (FaceTime, Zoom, Meet, OBS). Veja [ADR-007](../docs/decisions/ADR-007-extensao-coremediaio-independente.md). |
| `NexusTests` | Suíte de testes automatizados validando contratos de protocolo, máquina de estados de conexão, mapeamento de coordenadas e serviços de transferência. |

---

## 2. Princípios Arquiteturais no macOS

1. **Separação entre Preview e Webcam Virtual:** Receber e exibir o vídeo no `NexusApp` é independente da extensão `NexusCameraExtension` ([ADR-007](../docs/decisions/ADR-007-extensao-coremediaio-independente.md)).
2. **Isolamento do Núcleo (`NexusCore`):** Toda a lógica de protocolo, autenticação, reconexão e transferência deve residir em `NexusCore` para permitir testes unitários rápidos sem depender da interface SwiftUI.
3. **Armazenamento Seguro:** Chaves privadas e credenciais de dispositivos confiáveis devem utilizar o **macOS Keychain**.

