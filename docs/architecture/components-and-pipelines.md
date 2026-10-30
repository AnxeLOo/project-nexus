# Modelagem dos Componentes Críticos e Pipelines — Nexus

> Este documento consolida a **Seção 6 (Modelagem dos componentes críticos)** da especificação arquitetural do **Nexus**.

---

## 1. Streaming de vídeo de baixa latência

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

## 2. Túnel de rede local

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

## 3. Câmera virtual no macOS

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

## Referências Relacionadas

- [Arquitetura do Sistema (`docs/architecture/README.md`)](./README.md)
- [ADR-003 — WebRTC para Mídia](../decisions/ADR-003-webrtc-para-midia.md)
- [ADR-004 — Camera2 para Controles Avançados](../decisions/ADR-004-camera2-para-controles-avancados.md)
- [ADR-005 — TCP/TLS para Arquivos](../decisions/ADR-005-tcp-tls-para-arquivos.md)
- [ADR-007 — Extensão CoreMediaIO Independente](../decisions/ADR-007-extensao-coremediaio-independente.md)

