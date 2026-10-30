# Nexus Android

Aplicativo nativo Android responsável por captura de câmera (`Camera2`), espelhamento de tela (`MediaProjection`), execução de comandos remotos autorizados (`AccessibilityService`), transferência de arquivos, sincronização de área de transferência e pareamento seguro com o cliente **Nexus Desktop** (macOS).

---

## 1. Arquitetura em Camadas (Clean Architecture + MVVM)

O projeto segue **Clean Architecture + MVVM** (conforme [ADR-002](../docs/decisions/ADR-002-clean-architecture-mvvm.md)), separando responsabilidades em quatro camadas com dependências apontando para o domínio:

```text
Presentation (Compose UI / ViewModels)
       │
       ▼
Domain (Use Cases / Entities / Repository Contracts)
       ▲
       │
Data (Repository Implementations / Room / Protocol Mappers)
       │
       ▼
Platform Infrastructure (Camera2 / MediaProjection / WebRTC / Transport / Keystore / Accessibility)
```

> **Regra de ouro:** Os módulos da camada de domínio (`:core:model` e `:core:domain`) utilizam o plugin `org.jetbrains.kotlin.jvm` (Kotlin/JVM puro) e **não importam classes do framework Android, Room ou WebRTC**.

---

## 2. Organização de Diretórios e Módulos Gradle

```text
android/
├── app/                  # Inicialização (@HiltAndroidApp), navegação, tema Material 3 e composição de DI
├── core/                 # Módulos centrais compartilhados
│   ├── common/           # Qualificadores de CoroutineDispatcher, escopos (@ApplicationScope, etc.) e NexusResult
│   ├── model/            # Modelos de domínio em Kotlin/JVM puro (ConnectionState, TransportType, NexusOverview)
│   ├── domain/           # Contratos de repositório e casos de uso em Kotlin/JVM puro
│   ├── database/         # Persistência local via Room (DAOs, Entities, Migrations)
│   ├── network/          # Repositórios de sessão, adaptadores de conexão e módulos Hilt (NetworkDataModule)
│   ├── protocol/         # Serialização, validação e versionamento de mensagens
│   ├── security/         # Android Keystore, identidade e pareamento criptográfico
│   └── testing/          # Fakes (FakeNexusOverviewRepository) e regras JUnit (MainDispatcherRule)
├── feature/              # Funcionalidades de produto (Compose UI + ViewModel + UiState)
│   ├── dashboard/        # Tela inicial validando Material Design 3 (claro/escuro) e fluxo MVVM
│   ├── pairing/          # Descoberta e pareamento de dispositivos
│   ├── screenstream/     # Controle de espelhamento de tela
│   ├── remotecontrol/    # Configuração e status de controle remoto
│   ├── camera/           # Streaming de câmera e controles manuais
│   ├── filetransfer/     # Envio, recebimento e histórico de arquivos
│   ├── clipboard/        # Configuração de sincronização de área de transferência
│   ├── devices/          # Gestão de dispositivos confiáveis
│   └── settings/         # Preferências globais do aplicativo
└── platform/             # Integrações de baixo nível com APIs do Android
    ├── camera2/          # Captura avançada Camera2 e encoder H.264
    ├── mediaprojection/  # Captura de tela via MediaProjection
    ├── webrtc/           # Transporte de mídia em tempo real via WebRTC
    ├── transport/        # Sockets TCP/TLS e descoberta mDNS (NSD)
    └── accessibility/    # Execução de gestos e ações via AccessibilityService
```

---

## 3. Especificações Técnicas e Design System

- **Linguagem:** Kotlin `2.0.21` (JVM Target 17)
- **SDK:** `minSdk = 29` (Android 10) • `targetSdk = 35` (Android 15) • `compileSdk = 35`
- **UI & Design System:** Jetpack Compose + **Material Design 3** (`NexusTheme`)
  - Suporte nativo a **Tema Claro** e **Tema Escuro**, respeitando `isSystemInDarkTheme()` por padrão (`ThemePreference.SYSTEM`), com opção de seleção explícita na tela inicial.
  - Paleta de cores extraída dos protótipos oficiais em [`docs/prototypes/android/`](../docs/prototypes/android/home.html).
- **Injeção de Dependências:** Dagger Hilt (`2.52`) com KSP.

---

## 4. Variantes de Build

- **`debug`**:
  - `applicationIdSuffix = ".debug"` (`com.nexus.app.debug`), permitindo instalação lado a lado com a versão de produção.
  - `isDebuggable = true`, logs diagnósticos e ferramentas de preview do Compose habilitadas.
- **`release`**:
  - `isMinifyEnabled = true` e `isShrinkResources = true` com regras de otimização R8/ProGuard (`proguard-rules.pro`).
  - Credenciais de produção nunca devem ser versionadas no repositório.

---

## 5. Como Configurar, Compilar e Executar Localmente

### Pré-requisitos
1. **JDK 17** ou **JDK 21** instalado e configurado em `JAVA_HOME`.
2. **Android SDK** com `Android SDK Platform 35` e `Android SDK Build-Tools 35.0.0` instalados (via Android Studio Ladybug ou `sdkmanager`).
3. Variável `ANDROID_HOME` configurada apontando para o diretório do SDK (ex.: `~/Library/Android/sdk` no macOS) ou arquivo `android/local.properties` contendo:
   ```properties
   sdk.dir=/Users/<seu-usuario>/Library/Android/sdk
   ```

### Compilando via Linha de Comando

A partir da raiz do repositório, acesse a pasta `android/`:

```bash
cd android

# Compilar a variante Debug (gera APK em app/build/outputs/apk/debug/)
./gradlew assembleDebug

# Compilar a variante Release (gera APK otimizado em app/build/outputs/apk/release/)
./gradlew assembleRelease
```

### Executando os Testes Unitários

```bash
cd android

# Executar testes unitários de domínio (JVM puro) e de ViewModels
./gradlew :core:domain:test :feature:dashboard:testDebugUnitTest

# Executar toda a suíte de testes unitários do projeto
./gradlew test
```

### Executando no Android Studio ou Dispositivo/Emulador

1. Abra o Android Studio e selecione **Open** → escolha o diretório `android/` deste repositório.
2. Aguarde a sincronização do Gradle (*Gradle Sync*).
3. Selecione a configuração de execução **`app`** e um emulador ou dispositivo físico com **Android 10 (API 29) ou superior**.
4. Clique em **Run** (`^R` no macOS) ou instale diretamente via CLI com um dispositivo conectado:
   ```bash
   cd android && ./gradlew installDebug
   ```
