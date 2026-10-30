# Build, CI/CD e Execução Local — Nexus

> Este documento consolida a **Seção 12 (Build e release)** da especificação arquitetural do **Nexus**.

---

## 1. Build Variants

A configuração inicial deve conter dois build types:

| Variante | Objetivo |
|---|---|
| `debug` | Desenvolvimento, logs diagnósticos e testes locais. |
| `release` | Distribuição, otimizações e assinatura de produção. |

Se houver necessidade de versões específicas para demonstração ou recursos experimentais, poderão ser adicionados product flavors.

A configuração deve manter as credenciais de assinatura fora do controle de versão. As opções de build e a combinação entre build types e product flavors estão documentadas em [Configure build variants](https://developer.android.com/build/build-variants?utm_source=chatgpt.com).

---

## 2. Pipeline Sugerido

```text
Pull Request
     │
     ▼
Static Analysis
     ├── Lint
     ├── Kotlin Compilation
     └── Type / API Checks
     │
     ▼
Unit Tests
     │
     ▼
Build Debug
     │
     ▼
Integration Tests
     │
     ▼
Device / Performance Tests
     │
     ▼
Release Approval
     │
     ▼
Build Release
     ├── APK
     └── AAB
     │
     ▼
Signing and Artifact Validation
     │
     ▼
Release
```

Os testes que dependem de dispositivos físicos poderão ser executados em uma etapa específica, separada da validação rápida dos pull requests.

Para o macOS, o pipeline deverá compilar o aplicativo, executar testes automatizados e validar o empacotamento da extensão de câmera. A ativação e os testes de distribuição precisarão considerar os requisitos de segurança do sistema.

---

## 3. Configuração e Execução Local do Projeto Android

O projeto Android em [`android/`](../android/README.md) está estruturado com Gradle Kotlin DSL, Version Catalog (`gradle/libs.versions.toml`), `minSdk = 29` (Android 10) e `targetSdk = 35` (Android 15).

### Pré-requisitos
- **JDK 17** ou **JDK 21** instalado.
- **Android SDK** (`Platform 35` e `Build-Tools 35.0.0`) configurado via variável `ANDROID_HOME` ou `android/local.properties` (`sdk.dir=/caminho/para/Android/sdk`).

### Comandos principais

```bash
cd android

# Compilar variantes debug e release
./gradlew assembleDebug assembleRelease

# Executar testes unitários (domínio em JVM puro e ViewModels)
./gradlew test

# Instalar e executar a variante debug em um dispositivo/emulador conectado
./gradlew installDebug
```

Consulte [`android/README.md`](../android/README.md) para mais detalhes sobre os módulos Gradle e o sistema de design Material 3.

