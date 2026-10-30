# ADR-008: API de Controle Privada e Versionada sobre Conexão Persistente

- **Status:** Aceito
- **Data:** 2026-10-30
- **Subsistema:** Protocol (`platform:shared`)

---

## 1. Contexto

O **Nexus Android** e o **Nexus Desktop (macOS)** precisam trocar continuamente comandos de controle (início/parada de sessão, consulta de capacidades de câmera, aplicação de ISO/exposição/zoom, eventos de mouse/teclado do controle remoto, coordenação de transferências de arquivos, atualização de clipboard e heartbeat).

Criar um servidor HTTP REST tradicional para cada operação traria desvantagens para este cenário:
- Overhead de cabeçalhos e handshakes repetidos ou necessidade de servidores web embarcados em ambos os lados para comunicação bidirecional;
- Dificuldade para o smartphone e o desktop enviarem notificações assíncronas em tempo real com igualdade de papéis (peer-to-peer);
- Risco de quebra silenciosa de compatibilidade caso o aplicativo Android e o cliente macOS estejam em versões ligeiramente diferentes durante a evolução do projeto.

---

## 2. Decisão

Definir um **protocolo de controle próprio, privado e explicitamente versionado**, operando por meio de mensagens tipadas sobre uma **conexão persistente autenticada (TLS)**:

1. **Envelope Canônico Versionado:**
   Toda mensagem de controle inclui obrigatoriamente `protocolVersion`, `messageId`, `sessionId`, `type`, `timestamp` e `payload` (conforme documentado em [`protocol/README.md`](../../protocol/README.md)).
2. **Formato de Serialização:**
   - **Primeira versão (`protocolVersion: 1`):** Utilizar mensagens **JSON** tipadas (implementadas com `Kotlin Serialization` no Android e `Codable` no Swift) para facilitar a inspeção, depuração e criação de testes de contrato multiplataforma em `protocol/examples/`.
   - **Evolução futura:** A camada de serialização (`core:protocol` no Android e `NexusCore` no macOS) deve permanecer isolada atrás de interfaces para permitir a adoção de **Protocol Buffers** em versões futuras caso o volume de mensagens de entrada remota exija codificação binária mais compacta.
3. **Confirmação Explícita e Erros Estruturados:**
   Comandos que alteram estado (como `camera.setControls`, `screen.start`, `transfer.start`) devem receber uma confirmação explícita (`command.ack`) ou um erro estruturado (`command.error`) correlacionado pelo `messageId`.
4. **Validação Rigorosa:**
   Ambos os clientes devem validar `protocolVersion`, campos obrigatórios, autorização da sessão e limites máximos de tamanho de mensagem antes de processar qualquer payload.

---

## 3. Consequências

### Positivas
- **Baixa latência para comandos e eventos:** Uma única conexão TLS persistente transporta comandos bidirecionais, eventos de ponteiro/teclado e heartbeats sem overhead de novas conexões.
- **Detecção imediata de incompatibilidade:** O campo `protocolVersion` e a negociação de capacidades na abertura da sessão evitam falhas silenciosas de desserialização.
- **Depuração simples no MVP:** O uso inicial de JSON com schemas e exemplos compartilhados em `protocol/` acelera o desenvolvimento e os testes unitários cruzados entre Kotlin e Swift.

### Trade-offs e Cuidados
- **Delimitadores de frame na stream TCP/TLS:** Como o TCP é orientado a fluxo de bytes, o transporte do Plano de Controle deve usar enquadramento explícito (ex.: prefixo de tamanho de 4 bytes big-endian seguido do payload UTF-8) e impor tamanho máximo de frame para prevenir ataques ou bugs de exaustão de memória.
- **Deduplicação e idempotência:** O receptor deve usar `messageId` para correlacionar respostas e evitar reprocessamento acidental de comandos críticos.

