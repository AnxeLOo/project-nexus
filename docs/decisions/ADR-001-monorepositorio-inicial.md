# ADR-001: Adoção de Monorepositório Inicial

- **Status:** Aceito
- **Data:** 2026-10-30
- **Subsistema:** Foundation / Infraestrutura (`platform:shared`)

---

## 1. Contexto

O projeto **Nexus** é composto por dois sistemas nativos complementares que precisam colaborar estreitamente:

1. **Nexus Android** (Kotlin, Jetpack Compose, Camera2, MediaProjection, WebRTC, Room).
2. **Nexus Desktop** para macOS (Swift, SwiftUI, Network.framework, AVFoundation, CoreMediaIO, WebRTC).

Ambos os clientes compartilham um protocolo de controle privado, fluxos de autenticação e pareamento, máquinas de estado de sessão e contratos de transferência de arquivos e área de transferência.

Distribuir o código inicialmente em múltiplos repositórios separados (`nexus-android`, `nexus-macos`, `nexus-protocol`) introduziria custos operacionais elevados logo na fase fundacional:
- Dificuldade para manter os schemas do protocolo sincronizados entre Kotlin e Swift.
- Necessidade de múltiplos Pull Requests para implementar uma única funcionalidade de ponta a ponta.
- Fragmentação da documentação arquitetural, dos scripts de automação e do rastreamento de issues.

---

## 2. Decisão

Adotar um **monorepositório** estruturado com fronteiras claras no nível raiz:

```text
nexus/
├── android/      # Projeto Android nativo (Kotlin)
├── macos/        # Cliente e extensões macOS (Swift)
├── protocol/     # Schemas e exemplos canônicos independentes de plataforma
├── docs/         # Arquitetura, ADRs, protocolo e estratégia de testes
├── scripts/      # Automação de ambiente, backlog e validação
└── .github/      # Workflows de integração contínua
```

A pasta `protocol/` atuará como a fonte de verdade agnóstica às linguagens para validar a serialização em ambos os clientes.

---

## 3. Consequências

### Positivas
- **Evolução atômica do protocolo:** Uma alteração no contrato em `protocol/` pode ser acompanhada no mesmo commit/PR pelas implementações em Kotlin (`android/`) e Swift (`macos/`).
- **Testes de compatibilidade compartilhados:** Os payloads em `protocol/examples/` ficam diretamente acessíveis para as suítes de teste unitário de ambas as plataformas.
- **Documentação e governança unificadas:** ADRs, guias de arquitetura e Product Backlog permanecem centralizados junto ao código.

### Trade-offs e Cuidados
- **Isolamento de builds:** Os sistemas de build (Gradle para Android e Xcode/SwiftPM para macOS) devem permanecer independentes em suas respectivas pastas (`android/` e `macos/`), evitando acoplamento de ferramentas de compilação.
- **Controle de versão limpo:** O arquivo `.gitignore` raiz deve contemplar rigorosamente os artefatos gerados por ambos os ecossistemas.

