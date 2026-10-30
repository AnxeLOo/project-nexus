# ADR-003: Uso de WebRTC para Transporte de Mídia em Tempo Real

- **Status:** Aceito
- **Data:** 2026-10-30
- **Subsistema:** Camera Hub / Screen Hub (`platform:shared`)

---

## 1. Contexto

O Nexus precisa transmitir vídeo em tempo real do smartphone Android (câmera via `Camera2` e tela via `MediaProjection`) para o cliente macOS com baixa latência (meta inicial em protótipo: P95 < 150 ms em condições controladas, 1080p a 30 FPS ou 720p a 60 FPS).

Construir um protocolo de transporte de vídeo em tempo real sobre UDP puro a partir do zero exigiria projetar, implementar e depurar manualmente:
- Fragmentação e remontagem de quadros H.264 (NAL units);
- Controle de congestionamento e estimativa de largura de banda disponível;
- Recuperação de perda de pacotes (NACK, FEC, solicitação de Keyframe/PLI);
- Buffer de jitter adaptativo e sincronização de timestamps;
- Criptografia de mídia em trânsito.

---

## 2. Decisão

Utilizar **WebRTC** com preferência por codificação **H.264 acelerada por hardware** como o **Plano de Mídia** oficial do Nexus, tanto para o streaming de câmera quanto para o espelhamento de tela:

1. **No Android (`platform:webrtc`):** Os frames codificados pelo hardware (`MediaCodec` via `Surface`) alimentam uma `VideoSource` do WebRTC sem passar por armazenamento em disco e evitando cópias desnecessárias em CPU.
2. **No macOS (`NexusCore` / `NexusApp`):** O receptor WebRTC decodifica a trilha de vídeo e entrega os frames para renderização nativa via `AVFoundation` / `Metal` (e futuramente para a `Frame Bridge` da extensão de câmera virtual).
3. **Sinalização Local:** A troca de SDP (Offer/Answer) e candidatos ICE será realizada diretamente entre os dispositivos através do **Plano de Controle autenticado (TLS)** já estabelecido na rede local.
4. **Segurança:** O tráfego de mídia utiliza a proteção padrão do WebRTC (**DTLS-SRTP**).

---

## 3. Consequências

### Positivas
- **Redução drástica de risco técnico:** Reutiliza mecanismos maduros da indústria para adaptação de bitrate, controle de congestionamento, solicitação de keyframes e proteção contra jitter em redes Wi-Fi.
- **Compatibilidade multiplataforma:** Suporte consolidado a H.264 com aceleração por hardware tanto em dispositivos Android (`MediaCodec`) quanto em Macs (`VideoToolbox`).
- **Isolamento do plano de mídia:** O transporte de vídeo opera com semântica de tempo real, separado do canal TCP/TLS usado para transferências pesadas de arquivos ([ADR-005](./ADR-005-tcp-tls-para-arquivos.md)).

### Trade-offs e Cuidados
- **Complexidade de integração nativa:** A biblioteca WebRTC possui binários nativos volumosos e requer gerenciamento rigoroso de ciclo de vida (`PeerConnectionFactory`, `EglBase`, `VideoTrack`) para evitar vazamentos de memória ou recursos de câmera/GPU presos.
- **Sinalização e sessão continuam sob responsabilidade do Nexus:** O uso de WebRTC não substitui a necessidade de pareamento, autenticação e máquina de estados da sessão no Plano de Controle.

