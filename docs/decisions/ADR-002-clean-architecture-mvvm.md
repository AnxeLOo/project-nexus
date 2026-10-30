# ADR-002: Clean Architecture + MVVM no Aplicativo Android

- **Status:** Aceito
- **Data:** 2026-10-30
- **Subsistema:** Foundation / Arquitetura Android (`platform:android`)

---

## 1. Contexto

O aplicativo **Nexus Android** lida simultaneamente com interfaces reativas em Jetpack Compose, estado complexo de sessão de rede, persistência local (Room), operações criptográficas (Android Keystore) e APIs de sistema de baixo nível (`Camera2`, `MediaProjection`, `WebRTC`, `NsdManager`, `AccessibilityService`).

Se as regras de negócio (como a máquina de estados de conexão, validação de capacidades da câmera ou políticas de reconexão e transferência) ficarem acopladas a `Activity`, `Service`, `ViewModel` ou diretamente às classes de `Camera2` e `WebRTC`, o sistema se tornará difícil de testar unitariamente e frágil diante de mudanças nas APIs do Android.

---

## 2. Decisão

Adotar **Clean Architecture combinada com MVVM (Model-View-ViewModel)** e estado reativo unidirecional (`Coroutines` e `Flow`), dividindo o projeto Android em quatro camadas com limites explícitos:

1. **Presentation (`feature:*`, `app`):**
   - Telas em **Jetpack Compose** (Material Design 3) e `ViewModels`.
   - Consome casos de uso do domínio e expõe estados imutáveis (`UiState`) via `StateFlow`.
2. **Domain (`core:domain`, `core:model`):**
   - Contém entidades de domínio (`DeviceCapabilities`, `ConnectionState`, `StreamingSession`, `TransferProgress`, `CameraControlState`), casos de uso (*Use Cases*) e interfaces de repositórios/serviços.
   - **Restrição estrita:** O domínio é escrito em Kotlin puro e **não deve importar classes do framework Android, Room ou WebRTC**.
3. **Data (`core:database`, `core:network`, `core:protocol`, `core:security`):**
   - Implementa os contratos definidos pela camada `Domain`.
   - Coordena persistência no Room, serialização de mensagens e mapeamento entre entidades persistentes/DTOs e modelos de domínio.
4. **Platform Infrastructure (`platform:camera2`, `platform:mediaprojection`, `platform:webrtc`, `platform:transport`, `platform:accessibility`):**
   - Encapsula a integração direta com APIs nativas do Android e bibliotecas de mídia/transporte, implementando abstrações consumidas pelas camadas superiores.

Além disso, as operações concorrentes devem utilizar **escopos de Coroutines dedicados** (`viewModelScope`, escopo de conexão, escopo de streaming, escopo de transferência e escopo de aplicação), evitando um escopo global único.

---

## 3. Consequências

### Positivas
- **Alta testabilidade:** Toda a lógica de pareamento, máquina de estados de conexão, reconexão e validação de capacidades pode ser testada em JVM pura com *fakes* (ex.: `FakeConnectionRepository`), sem necessidade de emulador ou rede real.
- **Substituibilidade de infraestrutura:** Mudanças na implementação de sockets, WebRTC ou banco de dados não impactam casos de uso nem a camada de UI.
- **Ciclo de vida seguro:** Separar a infraestrutura de captura (`ForegroundService` de câmera/tela) da camada de apresentação permite que o streaming continue ativo independentemente da navegação entre telas.

### Trade-offs e Cuidados
- **Mapeamento entre camadas:** Exige modelos distintos para persistência (`Room Entities`), transporte (`Protocol DTOs`) e domínio (`Domain Models`), demandando funções de mapeamento explícitas.
- **Disciplina de modularização:** Módulos Gradle devem ser criados onde há fronteiras reais de dependência (`core:*`, `feature:*`, `platform:*`), evitando criar módulos excessivamente granulares para uma única classe.

