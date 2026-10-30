# ADR-007: Extensão de Câmera Virtual CoreMediaIO Independente no macOS

- **Status:** Aceito
- **Data:** 2026-10-30
- **Subsistema:** Virtual Camera (`platform:macos`)

---

## 1. Contexto

Um dos objetivos do **Nexus** é permitir que a câmera do smartphone Android seja utilizada em aplicativos de videoconferência e gravação no Mac (como FaceTime, Google Meet, Zoom e OBS).

Entretanto, no macOS existe uma distinção técnica fundamental entre dois recursos:
1. **Visualização de vídeo (Preview Window):** O aplicativo **Nexus Desktop** recebe o stream via WebRTC, decodifica os frames H.264 e os renderiza em uma janela própria usando `AVFoundation` / `Metal`.
2. **Webcam Virtual do Sistema:** Disponibilizar esse fluxo de vídeo como um dispositivo de câmera selecionável por processos de terceiros no macOS.

Nas versões modernas do macOS, câmeras virtuais são implementadas como **System Extensions** baseadas no framework **`CoreMediaIO`** (com componentes `CMIOExtensionProvider`, `CMIOExtensionDevice` e `CMIOExtensionStream`), que rodam em um processo isolado do aplicativo principal e exigem assinatura de código, entitlements específicos, aprovação do usuário nas Ajustes do Sistema e um mecanismo de IPC (*Frame Bridge*) para receber os frames decodificados.

Tentar acoplar a extensão de câmera virtual diretamente ao início do desenvolvimento do receptor de vídeo bloquearia a validação do pipeline básico de streaming na Fase 2 com complexidades de distribuição e permissões de sistema do macOS.

---

## 2. Decisão

Separar arquiteturalmente o recebimento/visualização de vídeo da webcam virtual no macOS:

1. **Módulo Isolado (`NexusCameraExtension`):** A câmera virtual será desenvolvida em um target dedicado em `macos/NexusCameraExtension/` utilizando a API moderna de `CoreMediaIO` Camera Extension.
2. **Comunicação via Frame Bridge:** O cliente principal (`NexusApp` / `NexusCore`) receberá o stream WebRTC, exibirá na janela de preview e, quando a câmera virtual estiver ativa, encaminhará os buffers de vídeo de forma eficiente para a extensão `CoreMediaIO`.
3. **Faseamento de Entrega (Redução de Risco):**
   - **Fase 2:** Implementar e validar completamente o receptor WebRTC e a janela de preview nativa no `NexusApp`.
   - **Fase 3:** Implementar a `NexusCameraExtension` (`CoreMediaIO`), o compartilhamento de buffers e o fluxo de instalação/ativação no macOS.

---

## 3. Consequências

### Positivas
- **Desbloqueio do desenvolvimento incremental:** Permite testar e validar latência, resolução, FPS e controles manuais da câmera (`Camera2` → `WebRTC` → `macOS Preview`) sem depender de entitlements de System Extension durante as Fases 1 e 2.
- **Isolamento de falhas:** Uma falha ou reinicialização na extensão de câmera ou no aplicativo consumidor (ex.: Zoom) não corrompe a sessão de controle nem o aplicativo principal do Nexus.
- **Conformidade com a plataforma Apple:** Utiliza a arquitetura moderna de `CoreMediaIO` System Extensions (substituta dos antigos plugins DAL depreciados pela Apple).

### Trade-offs e Cuidados
- **Custo de IPC / Conversão de Formato:** A `Frame Bridge` entre o `NexusCore` e a `NexusCameraExtension` deverá minimizar cópias de memória (utilizando `IOSurface` / `CMSampleBuffer` compartilhados quando aplicável) e garantir formato de pixel compatível.
- **Requisitos de Assinatura:** O teste completo de ativação da System Extension no macOS requer configuração adequada de assinatura de código e permissões do sistema operacional.

