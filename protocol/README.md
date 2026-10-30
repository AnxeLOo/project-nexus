# Protocolo de Comunicação do Nexus (`protocol/`)

Esta pasta contém a especificação canônica, os schemas de validação e os exemplos de payloads do protocolo de comunicação entre o **Nexus Android** e o **Nexus Desktop (macOS)**.

A pasta `protocol/` é **independente de linguagem** (agnóstica às implementações em Kotlin e Swift) e atua como a **única fonte de verdade (Single Source of Truth)** para todas as mensagens trocadas entre os dispositivos.

---

## 1. Estrutura da Pasta

```text
protocol/
├── schemas/      # Definições formais dos contratos de mensagens (JSON Schema / Protobuf)
├── examples/     # Exemplos válidos e inválidos de payloads para testes de conformidade
└── README.md     # Convenções de estrutura, versionamento e evolução do protocolo
```

---

## 2. Arquitetura de Planos de Comunicação

Conforme definido na arquitetura do Nexus ([ADR-008](../docs/decisions/ADR-008-api-de-controle-versionada.md)), a comunicação é dividida em três planos lógicos:

1. **Plano de Controle (Control Plane):** Autenticação, pareamento, negociação de sessão, comandos de câmera/tela, eventos de entrada e heartbeat sobre conexão persistente autenticada (TLS).
2. **Plano de Mídia (Media Plane):** Streaming de vídeo (câmera e tela) em tempo real via WebRTC (DTLS-SRTP), cuja sinalização trafega pelo Plano de Controle ([ADR-003](../docs/decisions/ADR-003-webrtc-para-midia.md)).
3. **Plano de Dados (Data Plane):** Transferência confiável de arquivos em blocos com verificação SHA-256 e sincronização de área de transferência sobre TCP/TLS ([ADR-005](../docs/decisions/ADR-005-tcp-tls-para-arquivos.md)).

---

## 3. Envelope Padrão de Mensagens

Todas as mensagens do Plano de Controle seguem um envelope versionado consistente:

```json
{
  "protocolVersion": 1,
  "messageId": "550e8400-e29b-41d4-a716-446655440000",
  "sessionId": "session-987654321",
  "type": "camera.setControls",
  "timestamp": 1793379600000,
  "payload": {
    "exposureMode": "manual",
    "iso": 400,
    "exposureTimeNs": 10000000
  }
}
```

### Campos Obrigatórios do Envelope

| Campo | Tipo | Descrição |
|---|---|---|
| `protocolVersion` | ` integer ` | Versão principal (major) do contrato de protocolo (ex.: `1`). |
| `messageId` | `string` | Identificador único da mensagem (UUID v4) para correlação de confirmação/erro e deduplicação. |
| `sessionId` | `string \| null` | Identificador da sessão autenticada ativa (`null` apenas durante o handshake inicial de pareamento/sessão). |
| `type` | `string` | Tipo qualificado da mensagem no formato `<dominio>.<acao>` (ex.: `session.start`, `camera.setControls`). |
| `timestamp` | `integer` | Timestamp Unix em milissegundos (UTC) no momento da emissão. |
| `payload` | `object` | Dados específicos da operação validados pelo schema correspondente ao `type`. |

---

## 4. Catálogo Inicial de Domínios e Tipos de Mensagem

| Domínio | Tipos de Mensagem | Finalidade |
|---|---|---|
| **Sessão e Saúde** | `session.start`, `session.stop`, `heartbeat`, `heartbeat.ack` | Ciclo de vida da sessão autenticada, negociação de capacidades e monitoramento de conectividade. |
| **Pareamento** | `pairing.request`, `pairing.challenge`, `pairing.confirm`, `pairing.result` | Negociação de identidade e estabelecimento de chaves de confiança. |
| **Câmera** | `camera.getCapabilities`, `camera.capabilities`, `camera.setControls` | Consulta de capacidades reais do sensor `Camera2` e ajuste remoto de parâmetros. |
| **Tela** | `screen.start`, `screen.stop` | Controle da sessão de espelhamento via `MediaProjection`. |
| **Entrada Remota** | `input.pointer`, `input.key` | Eventos normalizados de mouse, trackpad, gestos e teclado. |
| **Transferência** | `transfer.start`, `transfer.progress`, `transfer.cancel`, `transfer.complete` | Coordenação de envio de arquivos e verificação de integridade SHA-256. |
| **Clipboard** | `clipboard.update` | Sincronização de conteúdo textual da área de transferência. |
| **Respostas Padrão** | `command.ack`, `command.error` | Confirmação explícita ou retorno de erro estruturado para comandos que alteram estado. |

---

## 5. Convenção para Evolução dos Schemas e Versionamento

Para garantir que os clientes Android (`core:protocol`) e macOS (`NexusCore`) evoluam com segurança e sem quebras silenciosas de contrato, toda alteração em `protocol/` deve obedecer às seguintes regras:

### 5.1. Versionamento Semântico do Protocolo
1. **Mudanças Compatíveis (Retrocompatíveis — Mesmo `protocolVersion`):**
   - Adição de novos tipos de mensagem (`type`).
   - Adição de campos **opcionais** no `payload` com valores padrão bem definidos.
   - Receptores devem **ignorar campos desconhecidos** durante a desserialização (`ignoreUnknownKeys = true` no Kotlin Serialization / comportamento padrão do `Codable` no Swift).
2. **Mudanças Incompatíveis (Breaking Changes — Incremento de `protocolVersion`):**
   - Remoção ou renomeação de campos existentes.
   - Alteração do tipo primitivo ou estrutura de um campo existente.
   - Adição de campo obrigatório sem valor padrão em mensagens já existentes.
   - Alteração da semântica de uma mensagem existente.

### 5.2. Organização de Arquivos em `schemas/` e `examples/`
- Os schemas devem ser organizados por versão e domínio:
  - Exemplo: `protocol/schemas/v1/envelope.schema.json`, `protocol/schemas/v1/camera.schema.json`.
- Todo novo comando ou alteração de schema deve ser acompanhado de pelo menos um payload de exemplo em `protocol/examples/`:
  - Exemplo: `protocol/examples/v1/camera-set-controls.json`.
- Os exemplos em `protocol/examples/` são utilizados pelas suítes de teste automatizadas de **Android** e **macOS** para garantir compatibilidade cruzada de serialização.

### 5.3. Tratamento de Erros e Versões Incompatíveis
- Se um dispositivo receber uma mensagem com `protocolVersion` não suportada, deve rejeitar a operação imediatamente retornando uma mensagem `command.error` com código `UNSUPPORTED_PROTOCOL_VERSION` e encerrar ou impedir a ativação da sessão incompatível.
- Comandos que alteram o estado do dispositivo (ex.: `camera.setControls`, `screen.start`, `transfer.start`) exigem resposta explícita (`command.ack` ou `command.error`) referenciando o `messageId` original.

