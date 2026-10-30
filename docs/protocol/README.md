# Documentação do Protocolo e Estratégia de Comunicação — Nexus

> Este documento consolida a **Seção 3 (Fonte da API e estratégia de comunicação)** e as **Seções 5.2 e 5.3 (Fluxo de pareamento e Contrato de mensagens)** da especificação arquitetural do **Nexus**.

---

## 1. Origem da API e Estratégia de Comunicação

### 1.1. Origem da API

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

### 1.2. Tecnologias recomendadas

- **Android:** Kotlin, Coroutines, Flow, Camera2, MediaProjection e Room.
- **macOS:** Swift, SwiftUI, Network.framework, AVFoundation e CoreMediaIO.
- **Streaming:** WebRTC com suporte a H.264.
- **Protocolo:** Protocol Buffers para mensagens de controle tipadas, ou JSON na primeira versão para facilitar a depuração.
- **Persistência:** Room no Android e armazenamento local apropriado no macOS.
- **Descoberta:** DNS-SD/mDNS, utilizando APIs de descoberta disponíveis nas plataformas.
- **Segurança:** TLS, autenticação por dispositivo e chaves de sessão.

A biblioteca WebRTC pode ser utilizada para transportar mídia e dados, mas sua integração não elimina a necessidade de implementar pareamento, autorização, gerenciamento de sessões e regras de negócio.

### 1.3. Modelo de comunicação

O Nexus utilizará três planos lógicos.

- **Plano de controle:** responsável por autenticação, comandos, negociação de sessões, configuração da câmera e estado dos dispositivos.
- **Plano de mídia:** responsável pela transmissão de vídeo e, futuramente, áudio. Será otimizado para latência, evitando bloqueios causados por operações de disco ou processamento de arquivos.
- **Plano de dados:** responsável por arquivos, clipboard e transferências confiáveis. Priorizará integridade e recuperação de falhas, mesmo que isso implique maior latência.

Essa separação permite que uma transferência de arquivos grande aconteça sem prejudicar a transmissão da câmera.

---

## 2. Fluxo de Pareamento

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

---

## 3. Contrato de Mensagens

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

## 4. Fonte de Verdade dos Schemas (`/protocol`)

Os schemas formais, exemplos de payloads JSON e regras de evolução de versão residem na pasta raiz [`/protocol`](../../protocol/README.md):

- [`protocol/README.md`](../../protocol/README.md): Envelope padrão, domínios de comandos e regras de versionamento.
- `protocol/schemas/`: Definições formais dos contratos por versão.
- `protocol/examples/`: Payloads de referência consumidos nos testes de compatibilidade entre Kotlin (Android) e Swift (macOS).

Consulte também a [ADR-008 — API de Controle Versionada](../decisions/ADR-008-api-de-controle-versionada.md).
