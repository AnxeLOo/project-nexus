# Nexus Android

Aplicativo nativo Android responsável por captura de câmera (`Camera2`), espelhamento de tela (`MediaProjection`), execução de comandos remotos autorizados (`AccessibilityService`), transferência de arquivos, sincronização de área de transferência e pareamento seguro com o cliente **Nexus Desktop** (macOS).

---

## 1. Arquitetura em Camadas (Clean Architecture + MVVM)

O projeto segue **Clean Architecture + MVVM** (conforme [ADR-002](../docs/decisions/ADR-002-clean-architecture-mvvm.md)), separando responsabilidades em quatro camadas com dependências apontando para o domínio:

```text
Presentation (Compose UI / ViewModels)
       │
       ▼
Domain (Use Cases / Entities / Repository Contracts)
       ▲
       │
Data (Repository Implementations / Room / Protocol Mappers)
       │
       ▼
Platform Infrastructure (Camera2 / MediaProjection / WebRTC / Transport / Keystore / Accessibility)
```

> **Regra de ouro:** A camada `domain` não deve importar classes do framework Android, Room ou WebRTC.

---

## 2. Organização de Diretórios e Módulos

```text
android/
├── app/                  # Inicialização, navegação, tema Material 3 e composição de DI
├── core/                 # Módulos centrais compartilhados
│   ├── common/           # Utilitários, dispatchers e tipos base
│   ├── model/            # Modelos puros compartilhados
│   ├── domain/           # Entidades de domínio, contratos de repositório e casos de uso
│   ├── database/         # Persistência local via Room (DAOs, Entities, Migrations)
│   ├── network/          # Gerenciamento de sessão e adaptadores de conexão
│   ├── protocol/         # Serialização, validação e versionamento de mensagens
│   ├── security/         # Android Keystore, identidade e pareamento criptográfico
│   └── testing/          # Fakes, fixtures e utilitários para testes automatizados
├── feature/              # Funcionalidades de produto (UI + ViewModel + State)
│   ├── pairing/          # Descoberta e pareamento de dispositivos
│   ├── dashboard/        # Visão geral e status da sessão ativa
│   ├── screenstream/     # Controle de espelhamento de tela
│   ├── remotecontrol/    # Configuração e status de controle remoto
│   ├── camera/           # Streaming de câmera e controles manuais
│   ├── filetransfer/     # Envio, recebimento e histórico de arquivos
│   ├── clipboard/        # Configuração de sincronização de área de transferência
│   ├── devices/          # Gestão de dispositivos confiáveis
│   └── settings/         # Preferências globais do aplicativo
└── platform/             # Integrações de baixo nível com APIs do Android
    ├── camera2/          # Captura avançada Camera2 e encoder H.264
    ├── mediaprojection/  # Captura de tela via MediaProjection
    ├── webrtc/           # Transporte de mídia em tempo real via WebRTC
    ├── transport/        # Sockets TCP/TLS e descoberta mDNS (NSD)
    └── accessibility/    # Execução de gestos e ações via AccessibilityService
```

---

## 3. Variantes de Build

- **`debug`**: Desenvolvimento local, logs diagnósticos e inspeção de protocolo.
- **`release`**: Otimizações R8/ProGuard e assinatura de distribuição (credenciais nunca devem ser versionadas).

