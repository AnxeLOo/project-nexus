# Arquitetura Android, Modularização e Concorrência — Nexus

> Este documento consolida a **Seção 7 (Arquitetura Android: Clean Architecture + MVVM)**, as **Seções 8.2 e 8.3 (Estrutura detalhada do Android e de funcionalidades)** e a **Seção 9 (Concorrência, estado e ciclo de vida)** da especificação arquitetural do **Nexus**.

---

## 1. Arquitetura Android: Clean Architecture + MVVM

A arquitetura Android deverá separar três camadas principais:

1. **Presentation:** interface e gerenciamento do estado da tela.
2. **Domain:** regras de negócio e casos de uso.
3. **Data:** persistência, rede, protocolo e integração com recursos do dispositivo.

Os serviços de câmera, captura de tela e transporte de rede podem ser organizados como módulos de infraestrutura. Eles não devem concentrar as regras de negócio.

### 1.1. Fluxo entre camadas

```text
┌──────────────────────────────┐
│ Presentation                 │
│ Compose UI                   │
│ ViewModels                   │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Domain                       │
│ Use Cases                    │
│ Entities / Policies          │
│ Repository Interfaces        │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Data                         │
│ Repository Implementations   │
│ Room / Network / Mappers     │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Platform Infrastructure       │
│ Camera2 / MediaProjection    │
│ WebRTC / Sockets / Keystore  │
└──────────────────────────────┘
```

O domínio não deverá importar classes Android, Room ou WebRTC. Isso facilita os testes unitários e permite substituir implementações de infraestrutura sem alterar as regras de negócio.

Uma observação: embora o desenho acima seja vertical, as dependências devem apontar para abstrações do domínio. A camada Data implementa os contratos definidos pelo Domain.

### 1.2. Organização por funcionalidades

Recomendo combinar módulos técnicos com organização interna por funcionalidade.

Os módulos técnicos estabelecem limites de dependência. Dentro deles, as funcionalidades mantêm seus próprios componentes, evitando pastas genéricas que crescem indefinidamente.

A estrutura abaixo representa uma proposta inicial de organização, não uma obrigação de transformar cada pasta em um módulo Gradle.

---

## 2. Estrutura detalhada do Android

```text
android/
├── app/
│   └── src/
│       ├── main/
│       │   ├── java/com/nexus/app/
│       │   │   ├── NexusApplication.kt
│       │   │   ├── MainActivity.kt
│       │   │   ├── navigation/
│       │   │   └── di/
│       │   ├── res/
│       │   └── AndroidManifest.xml
│       ├── debug/
│       └── release/
│
├── core/
│   ├── common/
│   ├── model/
│   ├── domain/
│   ├── database/
│   ├── network/
│   ├── protocol/
│   ├── security/
│   └── testing/
│
├── feature/
│   ├── pairing/
│   ├── dashboard/
│   ├── screenstream/
│   ├── remotecontrol/
│   ├── camera/
│   ├── filetransfer/
│   ├── clipboard/
│   ├── devices/
│   └── settings/
│
└── platform/
    ├── camera2/
    ├── mediaprojection/
    ├── webrtc/
    ├── transport/
    └── accessibility/
```

### 2.1. Responsabilidades dos módulos

| Módulo | Responsabilidade |
|---|---|
| `app` | Inicialização, navegação, configuração global e composição das dependências. |
| `core:common` | Utilitários compartilhados, abstrações básicas e tipos comuns. |
| `core:model` | Modelos compartilhados entre funcionalidades, sem dependências de infraestrutura. |
| `core:domain` | Entidades de domínio, interfaces de repositórios e casos de uso. |
| `core:database` | Room, DAOs, entidades persistentes e migrações. |
| `core:network` | Gerenciamento das conexões e adaptadores de transporte. |
| `core:protocol` | Serialização, validação e versionamento das mensagens. |
| `core:security` | Identidade dos dispositivos, pareamento e gerenciamento criptográfico. |
| `core:testing` | Fakes, fixtures e utilitários de testes. |
| `feature:*` | Interface, ViewModels e coordenação de cada funcionalidade. |
| `platform:camera2` | Integração com a câmera e seus controles manuais. |
| `platform:mediaprojection` | Captura da tela do Android. |
| `platform:webrtc` | Integração com a implementação de WebRTC. |
| `platform:transport` | Sockets, conexões locais e descoberta de dispositivos. |
| `platform:accessibility` | Integração com recursos autorizados de acessibilidade. |

**Importante:** os módulos `platform:*` devem implementar contratos definidos em `core:domain` ou abstrações apropriadas de infraestrutura. O domínio não deve depender diretamente desses módulos.

A separação em módulos Gradle é útil quando há limites de dependência claros. Não é necessário criar um módulo para cada classe ou pacote.

### 2.2. Estrutura interna de uma funcionalidade

Exemplo para a funcionalidade de câmera:

```text
feature/camera/
└── src/
    ├── main/
    │   └── java/com/nexus/feature/camera/
    │       ├── ui/
    │       │   ├── CameraScreen.kt
    │       │   ├── CameraViewModel.kt
    │       │   ├── CameraUiState.kt
    │       │   └── components/
    │       │
    │       ├── domain/
    │       │   ├── GetCameraCapabilitiesUseCase.kt
    │       │   ├── UpdateCameraControlsUseCase.kt
    │       │   └── StartCameraStreamUseCase.kt
    │       │
    │       └── model/
    │           └── CameraSettingsUiModel.kt
    │
    └── test/
        └── java/com/nexus/feature/camera/
            ├── CameraViewModelTest.kt
            └── CameraUiStateTest.kt
```

Se o projeto crescer, os casos de uso poderão migrar para um módulo de domínio compartilhado, evitando dependências circulares entre funcionalidades.

A organização segue as recomendações de arquitetura do Android, que favorecem separação de responsabilidades, estado reativo e uso de Coroutines e Flow. Consulte o [guia oficial de arquitetura de aplicativos Android](https://developer.android.com/topic/architecture?utm_source=chatgpt.com).

---

## 3. Concorrência, estado e ciclo de vida

O Nexus terá operações concorrentes com características muito diferentes. Por isso, não recomendo utilizar um único escopo de Coroutines para todos os serviços.

### 3.1. Divisão dos escopos

| Escopo | Responsabilidade |
|---|---|
| `viewModelScope` | Operações relacionadas à interface e ao estado das telas. |
| Escopo de conexão | Heartbeat, monitoramento e gerenciamento da sessão de rede. |
| Escopo de streaming | Captura, envio e recebimento de mídia. |
| Escopo de transferência | Operações de arquivos, progresso e cancelamento. |
| Escopo de aplicação | Serviços compartilhados que precisam sobreviver à navegação entre telas. |

O streaming de câmera e a captura de tela exigem um ciclo de vida explícito, independente da navegação da interface.

Quando o sistema permitir execução em primeiro plano, o serviço deverá declarar o tipo correspondente e respeitar as permissões e restrições da versão do Android. Isso é especialmente importante para captura de tela e uso contínuo da câmera.

### 3.2. Máquina de estados da conexão

```text
DISCONNECTED
     │
     ▼
DISCOVERING
     │
     ▼
PAIRING
     │
     ▼
CONNECTING
     │
     ▼
CONNECTED
     │
     ├──────────────► RECONNECTING
     │                      │
     │                      ├──► CONNECTED
     │                      └──► FAILED
     │
     └──► DISCONNECTED
```

A máquina de estados deverá ter um único responsável por coordenar as transições.

Isso evita problemas como duas rotinas tentando iniciar uma conexão simultaneamente ou a interface exibir `Connected` enquanto o canal de mídia já foi encerrado.

### 3.3. Estratégia de reconexão

1. Detectar perda de conectividade ou expiração do heartbeat.
2. Marcar a sessão como degradada ou desconectada.
3. Encerrar recursos de transporte inválidos.
4. Tentar restabelecer a conexão com backoff exponencial e jitter.
5. Revalidar a identidade do dispositivo.
6. Renegociar os canais necessários.
7. Restaurar apenas as sessões que puderem ser retomadas com segurança.

Uma transferência de arquivo interrompida não deve ser considerada concluída apenas porque a conexão foi restabelecida. Seu estado precisa ser reconciliado e a integridade do conteúdo, verificada.

---

## Referências Relacionadas

- [README do Projeto Android (`android/README.md`)](../../android/README.md)
- [ADR-002 — Clean Architecture + MVVM](../decisions/ADR-002-clean-architecture-mvvm.md)
- [Modelagem de Entidades e Domínio (`docs/architecture/data-model.md`)](./data-model.md)

