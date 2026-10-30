# Estratégia de Testes e Qualidade — Nexus

Este diretório documenta os planos de teste, roteiros de validação em dispositivos físicos e benchmarks de desempenho do **Nexus**.

---

## Níveis de Validação

1. **Testes Unitários:**
   - Máquina de estados da conexão, políticas de reconexão com backoff exponencial e casos de uso de pareamento.
   - Serialização e validação de mensagens do protocolo (`protocolVersion`, campos obrigatórios, limites de tamanho).
   - Mapeamento de coordenadas (resolução lógica, orientação, escala) e cálculo de progresso de transferências.
   - `ViewModels` e emissão de estados reativos (`Flow` no Android / estado observável no macOS) usando *fakes* (ex.: `FakeConnectionRepository`).

2. **Testes de Integração:**
   - Persistência e migrações do banco local (`Room` no Android).
   - Compatibilidade cruzada de serialização entre Kotlin (`kotlinx.serialization`) e Swift (`Codable`) utilizando os artefatos de [`protocol/examples/`](../../protocol/README.md).
   - Integridade de transferência de arquivos (SHA-256), escrita em arquivo temporário e cancelamento sobre sockets locais.
   - Rejeição de conexões ou comandos vindos de dispositivos não autenticados ou revogados.

3. **Testes de UI:**
   - Fluxos completos de descoberta, pareamento, recuperação de conexão, início/encerramento de streaming, ajuste de controles de câmera e transferência de arquivos.

4. **Testes de Desempenho e Estabilidade:**
   - Medição de latência ponta a ponta de vídeo (meta inicial em protótipo: P95 < 150 ms em ambiente controlado).
   - Monitoramento de FPS efetivo, frames descartados, bitrate, uso de CPU/GPU, memória, comportamento térmico e bateria.

