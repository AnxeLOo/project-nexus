# ADR-004: Adoção da API Camera2 para Controles Manuais Avançados e Pipeline de Vídeo

- **Status:** Aceito
- **Data:** 2026-10-30
- **Subsistema:** Camera Hub (`platform:android`)

---

## 1. Contexto

Um dos diferenciais do **Nexus** para criadores de conteúdo, desenvolvedores e profissionais remotos é permitir que o usuário consulte as capacidades reais da câmera do smartphone e ajuste remotamente parâmetros manuais a partir do Mac:
- Sensibilidade **ISO** (`SENSOR_SENSITIVITY`);
- **Velocidade do obturador / tempo de exposição** (`SENSOR_EXPOSURE_TIME`);
- **Compensação de exposição** (`CONTROL_AE_EXPOSURE_COMPENSATION`);
- **Zoom óptico e digital** (`CONTROL_ZOOM_RATIO` / região de recorte);
- **Flash / Tocha** (`FLASH_MODE_TORCH`);
- Seleção de lentes físicas/lógicas, resolução e taxa de quadros.

Além disso, o pipeline de streaming requer que os frames capturados alimentem diretamente uma `Surface` conectada ao encoder de hardware (`MediaCodec` H.264) e ao pipeline WebRTC com controle fino de latência e sem passar por gravação em arquivo.

Embora a biblioteca **CameraX** simplifique fluxos convencionais de fotografia e gravação de arquivo (`Recorder`), sua abstração de alto nível não expõe de forma direta e uniforme todos os controles manuais de sensor combinados com um pipeline customizado de codificação para WebRTC.

---

## 2. Decisão

Adotar a API **`android.hardware.camera2` (Camera2)** no módulo `platform:camera2` como a camada base para inspeção de hardware, controle manual do sensor e captura de vídeo para streaming:

1. **Consulta prévia obrigatória de capacidades (`CameraCharacteristics`):** O aplicativo nunca deve presumir que qualquer dispositivo suporta ISO manual, determinada velocidade de obturador ou faixa de zoom. As capacidades reais são extraídas no modelo `DeviceCapabilities` e enviadas ao macOS antes de habilitar os controles na UI.
2. **Controle determinístico de `CaptureRequest`:** Ajustes de ISO, tempo de exposição, compensação, zoom e flash são aplicados diretamente na sessão de captura ativa (`CameraCaptureSession`), respeitando os limites do sensor e a taxa de quadros selecionada.
3. **Integração direta via `Surface`:** A sessão `Camera2` fornece frames diretamente para a `Surface` de captura/codificação do pipeline de vídeo, minimizando cópias em memória e uso de CPU.
4. **Uso seletivo de CameraX (opcional):** `CameraX` poderá ser considerado apenas em fluxos auxiliares simples onde o controle de baixo nível do encoder e do sensor não for necessário, mas **não** como substituto da `Camera2` no pipeline principal de streaming e controles manuais.

---

## 3. Consequências

### Positivas
- **Controle granular de hardware:** Acesso completo aos metadados do sensor (`INFO_SUPPORTED_HARDWARE_LEVEL`, `SENSOR_INFO_SENSITIVITY_RANGE`, `SENSOR_INFO_EXPOSURE_TIME_RANGE`).
- **Desempenho e baixa latência:** Caminho direto entre o ISP/câmera, a `Surface` do encoder de hardware H.264 e o `WebRTC VideoSource`.
- **Experiência honesta na UI:** O cliente macOS exibe apenas os controles efetivamente suportados pelo smartphone conectado.

### Trade-offs e Cuidados
- **Maior verbosidade e complexidade de estado:** A API `Camera2` exige gerenciamento explícito de callbacks assíncronos (`CameraDevice.StateCallback`, `CameraCaptureSession.StateCallback`), threads de background (`HandlerThread`/Coroutines) e fechamento seguro de recursos quando a sessão é interrompida.
- **Variação entre fabricantes (OEMs):** É necessário validar o nível de suporte de hardware (`LEGACY`, `LIMITED`, `FULL`, `LEVEL_3`) e degradar graciosamente para controles automáticos quando o modo manual (`CONTROL_AE_MODE_OFF`) não for suportado pelo dispositivo.

