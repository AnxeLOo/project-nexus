# Projeto: Nexus — Hub de Integração entre Android e macOS

## 1. Visão geral do produto

### 1.1. Nome e proposta de valor

**Nexus** é um aplicativo Android nativo que transforma o smartphone em uma extensão inteligente do Mac, permitindo integrar câmera, tela, arquivos, área de transferência e controles remotos em uma única solução.

O projeto será composto por dois sistemas complementares:

- **Nexus Android:** aplicativo nativo responsável por capturar imagens, transmitir vídeo, executar comandos autorizados, gerenciar arquivos e disponibilizar recursos do smartphone.
- **Nexus Desktop:** cliente e daemon para macOS responsável por receber os streams, controlar as sessões, gerenciar transferências e integrar os recursos do Android ao ambiente desktop.

O diferencial do projeto será a integração direta entre os dispositivos, priorizando baixa latência, segurança, desempenho e funcionamento na rede local, sem exigir que os dados sejam enviados a servidores externos.

### 1.2. Problema que o aplicativo resolve

A integração entre Android e macOS apresenta limitações quando o usuário precisa combinar funcionalidades que normalmente estão distribuídas entre diferentes aplicativos e soluções.

O Nexus pretende resolver quatro problemas principais:

1. **Fragmentação da integração:** reunir espelhamento de tela, controle remoto, transferência de arquivos e sincronização de clipboard em uma única plataforma.
2. **Limitações de videoconferência:** permitir que a câmera do smartphone funcione como uma fonte de vídeo de alta qualidade para aplicativos no Mac.
3. **Transferência de arquivos pouco integrada:** oferecer comunicação bidirecional com descoberta de dispositivos, pareamento seguro e transferências confiáveis.
4. **Dependência de serviços externos:** executar as principais operações diretamente entre os dispositivos, reduzindo dependências de infraestrutura na nuvem.

### 1.3. Público-alvo

| Público | Necessidade principal |
|---|---|
| Desenvolvedores de software | Testar aplicativos Android, inspecionar telas e controlar o dispositivo pelo Mac. |
| Criadores de conteúdo | Utilizar a câmera do smartphone em gravações e videoconferências. |
| Profissionais remotos | Compartilhar arquivos e integrar o smartphone ao fluxo de trabalho. |
| Usuários avançados | Automatizar tarefas e controlar dispositivos em uma rede local. |
| Fotógrafos e produtores de vídeo | Controlar parâmetros da câmera e utilizar o smartphone como fonte de vídeo. |

### 1.4. Funcionalidades principais

O produto será dividido em cinco subsistemas.

| Subsistema | Funcionalidades |
|---|---|
| **Screen Hub** | Espelhamento de tela, transmissão de vídeo e controle remoto por eventos de entrada. |
| **Camera Hub** | Captura de vídeo, streaming, controles manuais e seleção de resolução e taxa de quadros. |
| **File Hub** | Transferência bidirecional de arquivos, progresso, cancelamento e histórico. |
| **Clipboard Hub** | Sincronização de texto e compartilhamento de mídias leves. |
| **Device Hub** | Pareamento, descoberta, autenticação, heartbeat, reconexão e gerenciamento de sessões. |

O aplicativo deverá funcionar com três modos de conectividade:

- **USB:** opção prioritária para streaming com maior previsibilidade de latência, quando a implementação e os recursos disponíveis permitirem.
- **Wi-Fi:** opção principal para mobilidade, com descoberta e comunicação pela rede local.
- **Wi-Fi Direct:** alternativa para conexões diretas entre dispositivos compatíveis, quando oferecer vantagens sobre a infraestrutura de rede existente.

A seleção do transporte será independente dos módulos de negócio, permitindo alternar entre os meios de conexão sem reescrever a lógica de domínio.

---

## 2. Premissas técnicas e limitações importantes

Antes de definir a arquitetura, é necessário estabelecer três restrições que afetam diretamente a viabilidade do projeto.

### 2.1. Controle remoto do Android

Um aplicativo Android convencional não pode simular livremente toques em outros aplicativos apenas com permissões comuns.

Para implementar o controle remoto, será necessário avaliar duas alternativas:

- **AccessibilityService:** pode executar determinadas ações de acessibilidade e gestos autorizados pelo sistema. A viabilidade depende das APIs utilizadas, das restrições da versão do Android e das políticas aplicáveis à distribuição do aplicativo.
- **ADB ou integração privilegiada:** pode viabilizar formas mais abrangentes de controle em cenários de desenvolvimento, depuração ou dispositivos gerenciados, mas exige uma arquitetura e um processo de configuração diferentes.

A recomendação é desenvolver inicialmente um fluxo de controle baseado em um agente Android com permissões explícitas, avaliando separadamente os recursos que exigem ADB ou acesso privilegiado.

O Nexus não deve pressupor que um aplicativo comum conseguirá reproduzir todos os eventos de entrada em qualquer dispositivo.

### 2.2. Webcam virtual no macOS

Transmitir vídeo do Android para o Mac é diferente de disponibilizar esse vídeo como uma câmera selecionável em qualquer aplicativo.

A arquitetura deve distinguir dois recursos:

1. **Visualização de vídeo:** o cliente Nexus Desktop recebe e exibe o stream.
2. **Webcam virtual:** um componente específico do macOS disponibiliza o vídeo como fonte de câmera para aplicativos de terceiros.

Para o segundo recurso, a abordagem recomendada é investigar a API nativa de câmeras virtuais do macOS, utilizando um componente baseado em `CoreMediaIO` quando apropriado.

Isso evita tratar o recebimento de vídeo via WebRTC como se ele automaticamente criasse uma webcam disponível para outros aplicativos.

A compatibilidade com ferramentas como CamOps deverá ser validada separadamente, sem pressupor integração nativa.

### 2.3. Limites dos controles manuais da câmera

A API Camera2 permite consultar as capacidades de captura e configurar parâmetros manuais, mas os controles disponíveis variam conforme o hardware e a implementação do fabricante.

O Nexus deverá consultar as capacidades reais do dispositivo antes de expor cada controle.

| Controle | Estratégia |
|---|---|
| ISO | Configurar a sensibilidade por meio dos parâmetros de captura, quando suportado. |
| Velocidade do obturador | Configurar o tempo de exposição, respeitando os limites do sensor e a taxa de quadros. |
| Compensação de exposição | Ajustar a compensação em dispositivos que suportam o controle. |
| Zoom óptico | Utilizar as lentes e os níveis de zoom disponíveis no hardware. |
| Zoom digital | Ajustar a região de recorte da captura, conforme suportado. |
| Flash | Controlar o flash ou a tocha conforme o modo de captura e as capacidades do dispositivo. |

**Decisão arquitetural:** utilizar Camera2 como camada de controle avançado da câmera. CameraX poderá ser empregado para simplificar os fluxos de captura compatíveis, mas não deve ser tratado como substituto universal dos controles manuais de baixo nível.

Para requisitos estritos de ISO, exposição e integração com o encoder, uma implementação baseada diretamente em Camera2 pode oferecer o controle necessário.

---

# 3. Fonte da API e estratégia de comunicação

## 3.1. Origem da API

A API será desenvolvida como parte do próprio projeto. Entretanto, recomendo **não criar inicialmente um backend HTTP tradicional hospedado na nuvem**.

O problema exige comunicação em tempo real, transferência de dados volumosos e acesso a recursos locais. Por isso, a arquitetura deve combinar um protocolo de comunicação próprio com padrões estabelecidos para streaming e transporte seguro.

A solução será composta por três interfaces:

| Interface | Responsabilidade | Tecnologia sugerida |
|---|---|---|
| API de controle | Pareamento, sessões, configurações e comandos | Kotlin Serialization + mensagens JSON ou Protocol Buffers |
| Canal de streaming | Transmissão de áudio/vídeo e feedback de conectividade | WebRTC |
| Canal de transferência | Arquivos, mensagens de clipboard e dados de controle específicos | TCP/TLS ou WebRTC Data Channels |

A comunicação entre os dispositivos será implementada como uma API privada, consumida pelo aplicativo Android e pelo cliente macOS.

Não será necessário criar uma API REST para cada funcionalidade. A API de controle poderá usar mensagens tipadas sobre uma conexão persistente, reduzindo a complexidade de manter múltiplas conexões independentes.

### Tecnologias recomendadas

- **Android:** Kotlin, Coroutines, Flow, Camera2, MediaProjection e Room.
- **macOS:** Swift, SwiftUI, Network.framework, AVFoundation e CoreMediaIO.
- **Streaming:** WebRTC com suporte a H.264.
- **Protocolo:** Protocol Buffers para mensagens de controle tipadas, ou JSON na primeira versão para facilitar a depuração.
- **Persistência:** Room no Android e armazenamento local apropriado no macOS.
- **Descoberta:** DNS-SD/mDNS, utilizando APIs de descoberta disponíveis nas plataformas.
- **Segurança:** TLS, autenticação por dispositivo e chaves de sessão.

A biblioteca WebRTC pode ser utilizada para transportar mídia e dados, mas sua integração não elimina a necessidade de implementar pareamento, autorização, gerenciamento de sessões e regras de negócio.

## 3.2. Modelo de comunicação

O Nexus utilizará três planos lógicos.

**Plano de controle:** responsável por autenticação, comandos, negociação de sessões, configuração da câmera e estado dos dispositivos.

**Plano de mídia:** responsável pela transmissão de vídeo e, futuramente, áudio. Será otimizado para latência, evitando bloqueios causados por operações de disco ou processamento de arquivos.

**Plano de dados:** responsável por arquivos, clipboard e transferências confiáveis. Priorizará integridade e recuperação de falhas, mesmo que isso implique maior latência.

Essa separação permite que uma transferência de arquivos grande aconteça sem prejudicar a transmissão da câmera.

---

# 4. Entidades de dados

A modelagem deverá separar entidades persistentes, objetos de domínio e mensagens transitórias de rede.

## 4.1. Entidades persistentes

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

O uso de Room deverá seguir a documentação oficial do Android: [Room Persistence Library](https://developer.android.com/training/data-storage/room?utm_source=chatgpt.com).

## 4.2. Modelos de domínio

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

## 4.3. Principais relacionamentos

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

# 5. Arquitetura de alta visão

## 5.1. Diagrama de comunicação

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

## 5.2. Fluxo de pareamento

O pareamento deve estabelecer uma relação de confiança entre os dispositivos antes de permitir o controle remoto ou o envio de arquivos.

Fluxo proposto:

1. O Nexus Android inicia a descoberta de dispositivos disponíveis.
2. O Nexus Desktop anuncia sua presença na rede local.
3. O usuário seleciona o Mac no Android ou o Android no Mac.
4. Os dispositivos iniciam uma negociação de identidade.
5. O usuário confirma o pareamento por um código ou QR Code.
6. Os dispositivos estabelecem credenciais de confiança.
7. Uma sessão autenticada é criada.
8. O estado da conexão é publicado para a interface.

A descoberta via mDNS não deve ser tratada como autenticação. Um dispositivo encontrado na rede ainda precisa provar sua identidade.

Para o estabelecimento de confiança, pode-se utilizar criptografia de chave pública e um protocolo de pareamento autenticado. A implementação deve incluir proteção contra repetição de mensagens, expiração de desafios e revogação de dispositivos.

## 5.3. Contrato de mensagens

O protocolo deverá ser versionado desde a primeira implementação.

Exemplo conceitual de uma mensagem de controle:

```json
{
  "protocolVersion": 1,
  "messageId": "unique-message-id",
  "sessionId": "active-session-id",
  "type": "camera.setExposure",
  "timestamp": 1793379600000,
  "payload": {
    "mode": "manual",
    "iso": 400,
    "exposureTimeNs": 10000000
  }
}
```

O exemplo é ilustrativo. Em produção, mensagens de controle devem incluir validação de campos, autorização, tratamento de duplicatas quando necessário e limites de tamanho.

Para comandos que alteram o estado do dispositivo, o cliente deverá receber uma confirmação ou um erro estruturado.

Também recomendo que o protocolo tenha mensagens específicas para:

- `session.start` e `session.stop`;
- `camera.getCapabilities`;
- `camera.setControls`;
- `screen.start` e `screen.stop`;
- `input.pointer` e `input.key`;
- `transfer.start`, `transfer.progress` e `transfer.cancel`;
- `clipboard.update`;
- `heartbeat` e `heartbeat.ack`.

Os nomes são sugestões para o contrato inicial, não uma exigência de implementação literal.

---

# 6. Modelagem dos componentes críticos

## 6.1. Streaming de vídeo de baixa latência

O streaming será dividido em duas funcionalidades independentes: transmissão da tela e transmissão da câmera.

Embora compartilhem o transporte de mídia, as fontes de captura são diferentes e precisam de pipelines próprios.

### A. Pipeline de câmera

O fluxo de dados será:

```text
┌───────────────────────┐
│ Smartphone Camera     │
│ Sensor / ISP          │
└───────────┬───────────┘
            │
┌───────────▼───────────┐
│ Camera2               │
│ Manual Controls       │
│ Exposure / ISO / Zoom │
└───────────┬───────────┘
            │ Surface
┌───────────▼───────────┐
│ Hardware Video Encoder│
│ MediaCodec / H.264    │
└───────────┬───────────┘
            │ Encoded Frames
┌───────────▼───────────┐
│ WebRTC Video Source   │
│ RTP / Congestion Ctrl │
└───────────┬───────────┘
            │
            │ USB ou Wi-Fi
            │
┌───────────▼───────────┐
│ WebRTC Receiver       │
│ macOS                 │
└───────────┬───────────┘
            │
┌───────────▼───────────┐
│ Video Renderer        │
│ AVFoundation / Metal  │
└───────────────────────┘
```

A utilização de um encoder por hardware reduz a necessidade de processamento de vídeo por CPU. O caminho de captura deverá evitar conversões de formato e cópias de memória desnecessárias.

### B. Camera2 ou CameraX?

Minha recomendação é utilizar uma estratégia híbrida, com Camera2 como base para os controles avançados.

**Camera2 deve ser priorizada quando:**
- For necessário controlar ISO e tempo de exposição manualmente.
- O aplicativo precisar configurar diretamente uma `CaptureRequest`.
- Houver necessidade de consultar capacidades detalhadas do sensor.
- O encoder precisar consumir buffers por meio de uma `Surface`.

**CameraX deve ser priorizado quando:**
- O objetivo for simplificar a captura convencional.
- Os casos de uso disponíveis atenderem às necessidades.
- A produtividade e a compatibilidade entre dispositivos forem mais importantes do que o controle de baixo nível.

A documentação do Android descreve os recursos de captura e a arquitetura do CameraX em [CameraX VideoCapture](https://developer.android.com/media/camera/camerax/video-capture?authuser=86&utm_source=chatgpt.com). Já os controles manuais de exposição e sensibilidade são documentados na [API Camera2](https://developer.android.com/reference/android/hardware/camera2/CameraMetadata?authuser=2&utm_source=chatgpt.com).

**Ponto de atenção:** o `Recorder` do CameraX abstrai a codificação e não oferece controle arbitrário sobre todos os detalhes do encoder. Se o objetivo for alimentar diretamente um pipeline WebRTC com parâmetros precisos, pode ser necessário implementar a captura com Camera2 e integrar os buffers ao encoder e à fonte de vídeo do WebRTC.

### C. Estratégia de codificação

A implementação deverá:

1. Consultar as capacidades de câmera e encoder do dispositivo.
2. Selecionar resolução e taxa de quadros compatíveis.
3. Preferir H.264 com aceleração por hardware.
4. Alimentar o pipeline de mídia sem passar pelo armazenamento de arquivos.
5. Utilizar o controle de congestionamento do WebRTC.
6. Ajustar a taxa de bits conforme a qualidade da conexão.
7. Evitar filas de frames excessivamente grandes.
8. Reduzir resolução ou taxa de quadros quando necessário.

H.264 é um bom ponto de partida pela compatibilidade entre plataformas, mas o suporte efetivo à aceleração por hardware precisa ser verificado no Android e no Mac.

### D. Metas iniciais de desempenho

Os números abaixo são **metas de engenharia para os protótipos**, não resultados já medidos nem garantias para qualquer dispositivo.

| Métrica | Meta inicial |
|---|---|
| Resolução padrão | 1920 × 1080 |
| Taxa de quadros | 30 FPS |
| Perfil alternativo | 1280 × 720 a 60 FPS, quando suportado |
| Latência câmera → visualização | P95 inferior a 150 ms em condições controladas |
| Uso do encoder | Preferência por aceleração por hardware |
| Recuperação de conexão | Reconexão automática após interrupções recuperáveis |

Para validar a latência, registre timestamps na captura, no envio e no recebimento. Uma medição precisa de ponta a ponta exige relógios sincronizados ou uma metodologia de medição que compense a diferença entre os relógios dos dispositivos.

A métrica de latência deve ser avaliada separadamente em USB, Wi-Fi de 5 GHz e outras condições relevantes.

### E. Pipeline de espelhamento da tela

O espelhamento deve utilizar `MediaProjection`:

```text
Android Display
      │
      ▼
MediaProjection
      │
      ▼
Virtual Display / Surface
      │
      ▼
Hardware Encoder
      │
      ▼
WebRTC
      │
      ▼
macOS Renderer
      │
      ▼
Eventos de entrada autorizados
      │
      ▼
Android
```

O Android exige consentimento do usuário para iniciar uma sessão de captura de tela. Nas versões recentes, também há requisitos específicos para serviços em primeiro plano do tipo `mediaProjection`. Consulte a documentação oficial de [MediaProjection](https://developer.android.com/media/grow/media-projection?utm_source=chatgpt.com).

O serviço de streaming deverá gerenciar corretamente a autorização, a interrupção da captura, o ciclo de vida e o encerramento da sessão.

### F. Controle remoto e mapeamento de entrada

O Nexus Desktop deverá converter os eventos de mouse e teclado em comandos do protocolo.

Por exemplo:

```text
Mouse / Trackpad
       │
       ▼
Coordinate Mapping
       │
       ▼
Input Command
       │
       ▼
Authenticated Channel
       │
       ▼
Android Input Adapter
       │
       ▼
AccessibilityService ou mecanismo autorizado
```

O mapeamento de coordenadas deverá considerar:

- Resolução lógica do dispositivo.
- Orientação da tela.
- Área visível do stream.
- Escala aplicada na interface do Mac.
- Mudanças de resolução durante a sessão.

O sistema também deverá distinguir gestos contínuos, como arrastar, de ações discretas, como um toque.

A interface do Nexus precisa informar claramente quando o controle remoto não estiver disponível por limitações de permissão ou compatibilidade.

---

## 6.2. Túnel de rede local

O termo *túnel de rede local* será utilizado para descrever a comunicação autenticada e protegida entre os dispositivos, não um túnel VPN completo.

O Nexus deverá implementar uma camada de transporte independente do domínio.

```text
┌───────────────────────────────┐
│ Application Services          │
│ Camera / Clipboard / Files     │
└───────────────┬───────────────┘
                │
┌───────────────▼───────────────┐
│ Protocol Layer                │
│ Commands / Events / Payloads  │
└───────────────┬───────────────┘
                │
┌───────────────▼───────────────┐
│ Secure Transport              │
│ TLS / WebRTC DTLS-SRTP         │
└───────────────┬───────────────┘
                │
┌───────────────▼───────────────┐
│ Transport Adapter             │
│ TCP / UDP / WebRTC            │
└───────────────┬───────────────┘
                │
┌───────────────▼───────────────┐
│ Network                       │
│ Wi-Fi / Ethernet / USB Bridge │
└───────────────────────────────┘
```

### A. Escolha dos protocolos

| Operação | Transporte recomendado | Justificativa |
|---|---|---|
| Comandos de controle | Canal persistente autenticado sobre TLS | Confiabilidade e ordenação. |
| Vídeo | WebRTC | Transporte de mídia com mecanismos de adaptação à rede. |
| Arquivos | TCP/TLS | Transferência confiável, controle de fluxo e recuperação simples. |
| Clipboard | Canal de dados confiável | Mensagens pequenas e necessidade de entrega consistente. |
| Heartbeat | Canal de controle existente | Evitar conexões adicionais desnecessárias. |

O WebRTC também disponibiliza canais de dados para comunicação arbitrária entre pares. Veja a documentação de [WebRTC Data Channels](https://webrtc.org/getting-started/data-channels?utm_source=chatgpt.com).

**Não recomendo implementar um protocolo UDP de vídeo do zero na primeira versão.** Seria necessário desenvolver, testar e manter mecanismos de congestionamento, recuperação de pacotes, temporização, sincronização e adaptação à rede que já fazem parte do ecossistema WebRTC.

### B. Descoberta e estabelecimento de conexão

O fluxo de conexão deverá ser:

1. Descobrir o dispositivo usando mDNS ou uma alternativa compatível.
2. Verificar a identidade do dispositivo.
3. Autenticar a sessão.
4. Negociar capacidades e versão do protocolo.
5. Estabelecer os canais necessários.
6. Iniciar o heartbeat.
7. Publicar o estado `Connected`.

Em redes locais, WebRTC pode estabelecer uma conexão direta sem retransmitir o vídeo por um servidor externo. O protocolo de sinalização, porém, precisa ser implementado pelo projeto. A documentação oficial explica essa separação em [WebRTC Peer Connections](https://webrtc.org/getting-started/peer-connections?utm_source=chatgpt.com).

Para a primeira versão, recomendo implementar a sinalização diretamente entre os dispositivos, usando o canal de controle já autenticado. Um servidor de sinalização só deverá ser introduzido se houver uma necessidade concreta de conexão através de redes diferentes.

### C. Transferência de arquivos

O serviço de transferência deve oferecer:

- Transferência em blocos.
- Verificação de integridade por SHA-256.
- Progresso observável.
- Cancelamento.
- Tratamento de interrupções.
- Limites de tamanho configuráveis.
- Escrita em arquivo temporário antes da confirmação.
- Confirmação de conclusão somente após validação.

O fluxo será:

```text
Selecionar arquivo
       │
       ▼
Validar destino e permissões
       │
       ▼
Criar TransferRecord
       │
       ▼
Enviar metadados
       │
       ▼
Transferir blocos
       │
       ▼
Validar integridade
       │
       ▼
Confirmar e finalizar
```

A interface poderá acompanhar o progresso por meio de um `Flow<TransferProgress>`, sem precisar conhecer detalhes dos sockets.

### D. Clipboard compartilhado

O clipboard requer cuidados adicionais porque pode conter senhas, tokens, informações financeiras ou outros dados privados.

A sincronização deverá:

- Ser desativada por padrão ou habilitada por consentimento explícito no primeiro uso.
- Permitir ativação e desativação independente por dispositivo.
- Suportar inicialmente texto simples.
- Limitar o tamanho das mensagens.
- Impedir ciclos de sincronização entre os dispositivos.
- Evitar persistir o conteúdo em logs.
- Aplicar políticas específicas para imagens e outros formatos.

No Android, a leitura do clipboard em segundo plano pode sofrer restrições de privacidade. Portanto, não se deve projetar o produto presumindo acesso irrestrito ao clipboard em qualquer momento.

---

## 6.3. Câmera virtual no macOS

A câmera virtual será um módulo separado do cliente principal.

```text
Nexus Android
     │
     │ H.264 / WebRTC
     ▼
Nexus Desktop
     │
     ├──► Preview Window
     │
     └──► Frame Bridge
                 │
                 ▼
          Camera Extension
          CoreMediaIO
                 │
                 ▼
        FaceTime / Conferência
```

A extensão de câmera precisa publicar um dispositivo de vídeo que o macOS consiga reconhecer.

A Apple disponibiliza uma arquitetura de extensões de câmera baseada em `CoreMediaIO`, com componentes para provider, device e stream. A tecnologia é documentada em [Creating a Camera Extension with Core Media I/O](https://developer.apple.com/documentation/coremediaio/creating-a-camera-extension-with-core-media-i-o?utm_source=chatgpt.com).

O projeto deverá avaliar:

- Transporte dos frames recebidos até a extensão.
- Compartilhamento eficiente de buffers.
- Formatos de pixel suportados.
- Conversão entre H.264 e o formato esperado pela extensão.
- Instalação e ativação da extensão.
- Permissões e aprovação do usuário.
- Compatibilidade com aplicativos de videoconferência.

**Recomendação:** desenvolver primeiro o receptor de vídeo no aplicativo desktop. A extensão de câmera virtual deve ser uma etapa posterior, pois adiciona requisitos específicos de integração e distribuição no macOS.

---

# 7. Arquitetura Android: Clean Architecture + MVVM

A arquitetura Android deverá separar três camadas principais:

1. **Presentation:** interface e gerenciamento do estado da tela.
2. **Domain:** regras de negócio e casos de uso.
3. **Data:** persistência, rede, protocolo e integração com recursos do dispositivo.

Os serviços de câmera, captura de tela e transporte de rede podem ser organizados como módulos de infraestrutura. Eles não devem concentrar as regras de negócio.

## 7.1. Fluxo entre camadas

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

## 7.2. Organização por funcionalidades

Recomendo combinar módulos técnicos com organização interna por funcionalidade.

Os módulos técnicos estabelecem limites de dependência. Dentro deles, as funcionalidades mantêm seus próprios componentes, evitando pastas genéricas que crescem indefinidamente.

A estrutura abaixo representa uma proposta inicial de organização, não uma obrigação de transformar cada pasta em um módulo Gradle.

# 8. Estrutura de pastas e módulos

## 8.1. Organização do repositório

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
│   └── testing/
│
├── scripts/
├── .github/
│   └── workflows/
└── README.md
```

O monorepositório permite versionar o protocolo junto aos clientes, testar mudanças de contrato em conjunto e manter documentação técnica centralizada.

A pasta `protocol` deve ser independente das implementações específicas de Kotlin e Swift. Os schemas serão a fonte de verdade para as mensagens compartilhadas.

## 8.2. Estrutura detalhada do Android

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

### Responsabilidades dos módulos

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

## 8.3. Estrutura interna de uma funcionalidade

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

# 9. Concorrência, estado e ciclo de vida

O Nexus terá operações concorrentes com características muito diferentes. Por isso, não recomendo utilizar um único escopo de Coroutines para todos os serviços.

## 9.1. Divisão dos escopos

| Escopo | Responsabilidade |
|---|---|
| `viewModelScope` | Operações relacionadas à interface e ao estado das telas. |
| Escopo de conexão | Heartbeat, monitoramento e gerenciamento da sessão de rede. |
| Escopo de streaming | Captura, envio e recebimento de mídia. |
| Escopo de transferência | Operações de arquivos, progresso e cancelamento. |
| Escopo de aplicação | Serviços compartilhados que precisam sobreviver à navegação entre telas. |

O streaming de câmera e a captura de tela exigem um ciclo de vida explícito, independente da navegação da interface.

Quando o sistema permitir execução em primeiro plano, o serviço deverá declarar o tipo correspondente e respeitar as permissões e restrições da versão do Android. Isso é especialmente importante para captura de tela e uso contínuo da câmera.

## 9.2. Máquina de estados da conexão

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

### Estratégia de reconexão

1. Detectar perda de conectividade ou expiração do heartbeat.
2. Marcar a sessão como degradada ou desconectada.
3. Encerrar recursos de transporte inválidos.
4. Tentar restabelecer a conexão com backoff exponencial e jitter.
5. Revalidar a identidade do dispositivo.
6. Renegociar os canais necessários.
7. Restaurar apenas as sessões que puderem ser retomadas com segurança.

Uma transferência de arquivo interrompida não deve ser considerada concluída apenas porque a conexão foi restabelecida. Seu estado precisa ser reconciliado e a integridade do conteúdo, verificada.

---

# 10. As três fases do projeto

Recomendo dividir o desenvolvimento em três fases, organizadas por redução de riscos técnicos.

A principal decisão é **validar primeiro a comunicação entre os dispositivos**, antes de investir na integração avançada da câmera e na extensão de câmera virtual.

## Fase 1 — Fundação e MVP de conectividade

**Objetivo:** provar que o Android e o macOS conseguem descobrir, parear e trocar dados de maneira confiável.

### Escopo

- Estrutura do monorepositório.
- Configuração inicial dos projetos Android e macOS.
- Protocolo de comunicação versionado.
- Descoberta por mDNS.
- Pareamento seguro.
- Persistência de dispositivos pareados.
- Gerenciamento de conexão e reconexão.
- Transferência bidirecional de arquivos.
- Sincronização de clipboard textual.
- Histórico de transferências.
- Testes unitários do protocolo e da máquina de estados.

### Critérios de conclusão

- Os dispositivos conseguem se descobrir e parear na mesma rede local.
- A comunicação é autenticada e criptografada.
- Arquivos transferidos passam pela verificação de integridade.
- A conexão consegue se recuperar de interrupções temporárias.
- O estado da conexão é refletido corretamente na interface.
- Os fluxos críticos possuem testes automatizados.

**Resultado esperado:** uma plataforma funcional de integração local, com arquitetura preparada para receber os subsistemas de mídia.

## Fase 2 — Streaming, câmera e controle remoto

**Objetivo:** transformar a comunicação básica em uma solução multimídia interativa.

### Escopo

- Captura de tela com MediaProjection.
- Streaming de tela via WebRTC.
- Streaming de câmera com Camera2.
- Codificação H.264.
- Aceleração por hardware quando suportada.
- Visualização do vídeo no macOS.
- Controles manuais da câmera.
- Consulta de capacidades de cada dispositivo.
- Mapeamento de eventos de mouse e trackpad.
- Implementação do mecanismo autorizado de controle remoto.
- Monitoramento de latência, uso de CPU e consumo de bateria.

### Critérios de conclusão

- O vídeo pode ser recebido e exibido no Mac.
- A latência é medida em condições controladas.
- Os controles da câmera respeitam as capacidades reais do hardware.
- O controle remoto funciona nos cenários de permissão explicitamente suportados.
- A interrupção da sessão encerra corretamente os recursos de captura.
- Os fluxos de mídia não bloqueiam as transferências de arquivos.

**Resultado esperado:** um MVP capaz de espelhar a tela, transmitir a câmera e executar ações remotas autorizadas.

## Fase 3 — Webcam virtual, otimização e distribuição

**Objetivo:** preparar o Nexus para uso cotidiano e distribuição.

### Escopo

- Extensão de câmera virtual para macOS.
- Integração com o pipeline de vídeo do desktop.
- Otimização de buffers e consumo de memória.
- Ajuste de parâmetros de streaming conforme a rede.
- Melhorias de segurança e gerenciamento de dispositivos confiáveis.
- Testes de integração em diferentes modelos de Android.
- Testes de desempenho e estabilidade prolongada.
- Configuração de build variants.
- Assinatura de APK/AAB.
- Assinatura e empacotamento do aplicativo macOS.
- Documentação de instalação e recuperação de falhas.

### Critérios de conclusão

- O Nexus pode ser selecionado como fonte de câmera em aplicativos compatíveis.
- Os testes de desempenho atendem às metas definidas para os dispositivos de referência.
- A extensão é instalada e ativada conforme os requisitos do macOS.
- O aplicativo consegue encerrar e recuperar sessões sem deixar recursos presos.
- Os artefatos de release são reproduzíveis e assinados adequadamente.
- A documentação permite instalar e configurar o produto sem depender do ambiente de desenvolvimento.

**Resultado esperado:** uma versão pronta para testes com usuários, com os principais recursos de integração e distribuição implementados.

---

# 11. Estratégia de testes e qualidade

A qualidade deve ser validada em três níveis: domínio, integração e comportamento real nos dispositivos.

## 11.1. Testes unitários

Priorizar:

- Casos de uso de pareamento.
- Máquina de estados da conexão.
- Regras de reconexão.
- Validação de mensagens.
- Controle de permissões e capacidades.
- Regras de transferência.
- Cálculo de progresso.
- Mapeamento de coordenadas.
- ViewModels e emissão de estados por Flow.

Sempre que possível, utilize fakes para substituir serviços externos. Por exemplo, um `FakeConnectionRepository` permite testar reconexões sem depender de uma conexão Wi-Fi real.

## 11.2. Testes de integração

| Componente | Teste |
|---|---|
| Room | Persistência, consultas e migrações. |
| Protocolo | Compatibilidade de serialização entre Kotlin e Swift. |
| Transporte | Envio, recebimento e encerramento de conexões. |
| WebRTC | Negociação de sessão e transmissão de frames. |
| Camera2 | Aplicação e validação dos parâmetros de captura. |
| Transferência | Interrupção, cancelamento e validação de integridade. |
| Segurança | Rejeição de dispositivos não autorizados. |

## 11.3. Testes de UI

Os fluxos mais importantes são:

1. Descobrir e parear um dispositivo.
2. Recuperar uma conexão perdida.
3. Iniciar e encerrar o streaming.
4. Configurar a câmera.
5. Iniciar, acompanhar e cancelar uma transferência.
6. Ativar ou desativar o clipboard compartilhado.

A interface deve apresentar estados explícitos de carregamento, erro, conexão e indisponibilidade de recursos.

## 11.4. Testes de desempenho

As medições deverão incluir:

- Latência de vídeo.
- FPS efetivo.
- Frames descartados.
- Bitrate.
- Uso de CPU e GPU.
- Consumo de memória.
- Temperatura e comportamento térmico.
- Consumo de bateria.
- Tempo de reconexão.
- Taxa de sucesso de transferências.

Para desempenho Android, considere Macrobenchmark, Baseline Profiles e otimizações de release. As recomendações estão disponíveis no [guia de arquitetura do Android](https://developer.android.com/topic/architecture/recommendations?hl=en&utm_source=chatgpt.com).

---

# 12. Build e release

## 12.1. Build variants

A configuração inicial deve conter dois build types:

| Variante | Objetivo |
|---|---|
| `debug` | Desenvolvimento, logs diagnósticos e testes locais. |
| `release` | Distribuição, otimizações e assinatura de produção. |

Se houver necessidade de versões específicas para demonstração ou recursos experimentais, poderão ser adicionados product flavors.

A configuração deve manter as credenciais de assinatura fora do controle de versão. As opções de build e a combinação entre build types e product flavors estão documentadas em [Configure build variants](https://developer.android.com/build/build-variants?utm_source=chatgpt.com).

## 12.2. Pipeline sugerido

```text
Pull Request
     │
     ▼
Static Analysis
     ├── Lint
     ├── Kotlin Compilation
     └── Type / API Checks
     │
     ▼
Unit Tests
     │
     ▼
Build Debug
     │
     ▼
Integration Tests
     │
     ▼
Device / Performance Tests
     │
     ▼
Release Approval
     │
     ▼
Build Release
     ├── APK
     └── AAB
     │
     ▼
Signing and Artifact Validation
     │
     ▼
Release
```

Os testes que dependem de dispositivos físicos poderão ser executados em uma etapa específica, separada da validação rápida dos pull requests.

Para o macOS, o pipeline deverá compilar o aplicativo, executar testes automatizados e validar o empacotamento da extensão de câmera. A ativação e os testes de distribuição precisarão considerar os requisitos de segurança do sistema.

## 12.3. Configuração e execução local do projeto Android

O projeto Android em [`android/`](android/README.md) está estruturado com Gradle Kotlin DSL, Version Catalog (`gradle/libs.versions.toml`), `minSdk = 29` (Android 10) e `targetSdk = 35` (Android 15).

### Pré-requisitos
- **JDK 17** ou **JDK 21** instalado.
- **Android SDK** (`Platform 35` e `Build-Tools 35.0.0`) configurado via variável `ANDROID_HOME` ou `android/local.properties` (`sdk.dir=/caminho/para/Android/sdk`).

### Comandos principais

```bash
cd android

# Compilar variantes debug e release
./gradlew assembleDebug assembleRelease

# Executar testes unitários (domínio em JVM puro e ViewModels)
./gradlew test

# Instalar e executar a variante debug em um dispositivo/emulador conectado
./gradlew installDebug
```

Consulte [`android/README.md`](android/README.md) para mais detalhes sobre os módulos Gradle e o sistema de design Material 3.

---

# 13. Decisões arquiteturais recomendadas

Para evitar retrabalho, eu registraria as seguintes decisões em documentos ADR (*Architecture Decision Records*).

| ID | Decisão | Justificativa |
|---|---|---|
| ADR-001 | Monorepositório inicial | Facilita a evolução conjunta dos clientes e do protocolo. |
| ADR-002 | Clean Architecture + MVVM | Separa regras de negócio, interface e infraestrutura. |
| ADR-003 | WebRTC para mídia | Evita implementar do zero um protocolo de streaming em tempo real. |
| ADR-004 | Camera2 para controles avançados | Oferece acesso aos parâmetros manuais suportados pelo hardware. |
| ADR-005 | TCP/TLS para arquivos | Simplifica confiabilidade, integridade e recuperação. |
| ADR-006 | Room para dados locais | Mantém configurações e histórico disponíveis entre execuções. |
| ADR-007 | Extensão CoreMediaIO independente | Isola a integração de câmera virtual das demais funcionalidades. |
| ADR-008 | API de controle versionada | Permite evoluir os clientes sem quebrar contratos silenciosamente. |
| ADR-009 | Sem servidor de mídia obrigatório | Prioriza comunicação direta e privacidade na rede local. |
| ADR-010 | Controle remoto baseado em permissões explícitas | Respeita as limitações de segurança do Android. |

---

# 14. Priorização do desenvolvimento

Embora o produto tenha cinco subsistemas, eu não os desenvolveria simultaneamente.

A ordem recomendada é:

| Prioridade | Entrega | Motivo |
|---|---|---|
| P0 | Descoberta, pareamento e conexão segura | Estabelece a base para todas as outras funcionalidades. |
| P0 | Protocolo e gerenciamento de sessões | Evita duplicação de lógica entre os clientes. |
| P1 | Transferência de arquivos | Valida a comunicação bidirecional e a recuperação de falhas. |
| P1 | Streaming de câmera com preview no Mac | Valida o caminho de mídia antes da integração mais complexa. |
| P1 | Espelhamento de tela | Reutiliza o transporte de mídia, mas exige permissões e captura específicas. |
| P2 | Controles manuais avançados | Depende da validação das capacidades do hardware. |
| P2 | Controle remoto | Depende da estratégia de entrada autorizada e da experiência de uso. |
| P3 | Webcam virtual | Exige integração específica com o macOS. |
| P3 | Otimização avançada de USB e desempenho | Deve ser orientada pelos resultados das medições. |

A sincronização de clipboard textual pode ser desenvolvida durante a Fase 1, pois seu custo de implementação é relativamente baixo em comparação aos subsistemas de vídeo.

---

# 15. Conclusão e recomendação técnica

O Nexus deve ser tratado como uma plataforma de integração entre dispositivos, e não simplesmente como um aplicativo Android que transmite vídeo.

O produto depende da colaboração entre duas implementações nativas, um protocolo versionado, serviços de infraestrutura e integrações específicas de cada sistema operacional.

A arquitetura proposta tem cinco pilares:

1. **Android nativo com Kotlin:** responsável pela captura, pelos controles do dispositivo e pela interface móvel.
2. **Clean Architecture + MVVM:** responsável pela separação das regras de negócio, da persistência e da interface.
3. **WebRTC:** responsável pelo transporte de mídia em tempo real e, quando apropriado, por canais de dados.
4. **Cliente macOS nativo em Swift:** responsável pelo recebimento dos streams, pela experiência desktop e pela integração com recursos do sistema.
5. **Protocolo próprio e seguro:** responsável pelo pareamento, pelos comandos, pelo gerenciamento das sessões e pela compatibilidade entre as plataformas.
