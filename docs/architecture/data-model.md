# Modelagem de Entidades e Domínio — Nexus

> Este documento consolida a **Seção 4 (Entidades de dados)** da especificação arquitetural do **Nexus**.

A modelagem deverá separar entidades persistentes, objetos de domínio e mensagens transitórias de rede.

---

## 1. Entidades persistentes

| Entidade | Campos principais | Finalidade |
|---|---|---|
| `PairedDevice` | `id`, `name`, `platform`, `publicKey`, `lastSeenAt`, `createdAt` | Representar dispositivos pareados. |
| `DeviceConnection` | `id`, `deviceId`, `transport`, `status`, `connectedAt`, `lastHeartbeatAt` | Registrar informações relevantes sobre uma conexão. |
| `CameraProfile` | `id`, `name`, `resolution`, `frameRate`, `iso`, `exposureTimeNs`, `zoomRatio` | Persistir configurações de câmera. |
| `TransferRecord` | `id`, `deviceId`, `fileName`, `sizeBytes`, `direction`, `status`, `createdAt` | Manter o histórico de transferências. |
| `AppSettings` | `id`, `preferredTransport`, `autoReconnect`, `clipboardSyncEnabled` | Armazenar preferências globais. |
| `TrustedDeviceKey` | `deviceId`, `keyId`, `keyMaterialReference`, `createdAt`, `revokedAt` | Controlar a identidade e a confiança entre dispositivos. |

Algumas decisões importantes:

- A chave privada do dispositivo não deve ser armazenada em texto simples no banco de dados. Sempre que possível, utilize o Android Keystore.
- O histórico de transferências deve armazenar metadados, não necessariamente o conteúdo dos arquivos.
- `CameraProfile` não deve presumir que todos os dispositivos suportam ISO manual, todas as lentes ou qualquer velocidade de obturador.
- O estado de uma conexão ativa não precisa ser persistido continuamente no Room. Ele deve permanecer prioritariamente em memória, sendo atualizado no banco apenas quando houver necessidade de histórico ou recuperação.

O uso de Room deverá seguir a documentação oficial do Android: [Room Persistence Library](https://developer.android.com/training/data-storage/room?utm_source=chatgpt.com). Consulte também a [ADR-006 — Room para Dados Locais](../decisions/ADR-006-room-para-dados-locais.md).

---

## 2. Modelos de domínio

Além das entidades persistentes, recomendo os seguintes modelos:

```text
DeviceCapabilities
    cameras
    supportedResolutions
    supportedFrameRates
    supportedCodecs
    manualSensorSupported
    supportedZoomRange
    flashAvailable

ConnectionState
    Disconnected
    Discovering
    Pairing
    Connecting
    Connected
    Reconnecting
    Failed

StreamingSession
    sessionId
    deviceId
    streamType
    resolution
    frameRate
    codec
    startedAt

TransferProgress
    transferId
    bytesTransferred
    totalBytes
    percentage
    transferStatus

CameraControlState
    exposureMode
    iso
    exposureTimeNs
    exposureCompensation
    zoomRatio
    flashMode
```

Os modelos de domínio não devem depender de Room, Android UI ou WebRTC. Eles representam os conceitos necessários para as regras de negócio.

---

## 3. Principais relacionamentos

```text
PairedDevice
 ├── DeviceConnection
 ├── TrustedDeviceKey
 ├── TransferRecord
 └── StreamingSession [transitória]

CameraProfile
 └── DeviceCapabilities [validação de compatibilidade]

AppSettings
 ├── Preferência de conexão
 ├── Reconexão automática
 └── Sincronização de clipboard
```

`StreamingSession` pode existir apenas em memória, enquanto `TransferRecord` e `CameraProfile` são candidatos naturais à persistência.

---

## Referências Relacionadas

- [Arquitetura do Sistema (`docs/architecture/README.md`)](./README.md)
- [Arquitetura Android e Concorrência (`docs/architecture/android-architecture.md`)](./android-architecture.md)
- [ADR-006 — Room para Dados Locais](../decisions/ADR-006-room-para-dados-locais.md)

