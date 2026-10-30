# Estratégia de Testes e Qualidade — Nexus

> Este documento consolida a **Seção 11 (Estratégia de testes e qualidade)** da especificação arquitetural do **Nexus**.

A qualidade deve ser validada em três níveis: domínio, integração e comportamento real nos dispositivos.

---

## 1. Testes unitários

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

---

## 2. Testes de integração

| Componente | Teste |
|---|---|
| Room | Persistência, consultas e migrações. |
| Protocolo | Compatibilidade de serialização entre Kotlin e Swift ([`protocol/examples/`](../../protocol/README.md)). |
| Transporte | Envio, recebimento e encerramento de conexões. |
| WebRTC | Negociação de sessão e transmissão de frames. |
| Camera2 | Aplicação e validação dos parâmetros de captura. |
| Transferência | Interrupção, cancelamento e validação de integridade. |
| Segurança | Rejeição de dispositivos não autorizados. |

---

## 3. Testes de UI

Os fluxos mais importantes são:

1. Descobrir e parear um dispositivo.
2. Recuperar uma conexão perdida.
3. Iniciar e encerrar o streaming.
4. Configurar a câmera.
5. Iniciar, acompanhar e cancelar uma transferência.
6. Ativar ou desativar o clipboard compartilhado.

A interface deve apresentar estados explícitos de carregamento, erro, conexão e indisponibilidade de recursos.

---

## 4. Testes de desempenho

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
