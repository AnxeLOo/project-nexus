# Configuração e Automação do Product Backlog no GitHub Projects

Este documento descreve a organização do **Product Backlog inicial do Nexus**, a arquitetura do quadro Kanban no **GitHub Projects (Projects V2)** e os procedimentos/comandos utilizando a **GitHub CLI (`gh`)** para criar, configurar ou reproduzir toda a estrutura no repositório [`AnxeLOo/project-nexus`](https://github.com/AnxeLOo/project-nexus).

---

## 1. Visão Geral da Organização do Backlog

O Product Backlog foi estruturado para orientar o desenvolvimento incremental do **Nexus** com foco na redução progressiva de riscos técnicos (conforme a estratégia definida no [`README.md`](../README.md) e em [`docs/recomendation.md`](./recomendation.md)):

1. **Fase 1 — Fundação e MVP de Conectividade (`phase:1-foundation`)**: Estruturação do monorepositório, configuração inicial dos projetos Android e macOS, protocolo de controle versionado, descoberta mDNS, pareamento seguro com chaves de dispositivo, máquina de estados de conexão sobre TLS, transferência de arquivos com verificação SHA-256 e sincronização de clipboard textual.
2. **Fase 2 — Streaming, Câmera e Controle Remoto (`phase:2-streaming`)**: Integração WebRTC com sinalização pelo canal de controle autenticado, streaming de câmera Android (`Camera2` + `MediaCodec` H.264) para janela nativa no macOS, espelhamento de tela via `MediaProjection`, controles manuais de câmera (`CameraProfile`), controle remoto autorizado via `AccessibilityService` e telemetria de latência.
3. **Fase 3 — Webcam Virtual, Otimização e Distribuição (`phase:3-distribution`)**: Extensão de câmera virtual no macOS baseada em `CoreMediaIO`, suporte e otimização de transporte via USB Bridge, testes de estabilidade prolongada e empacotamento/assinatura de release.

---

## 2. Estrutura do Quadro Kanban (GitHub Projects)

### 2.1. Colunas do Fluxo de Trabalho (Campo `Status`)

| Coluna | Cor | Significado no Fluxo |
|---|---|---|
| **Backlog** | `GRAY` | Tarefas mapeadas, priorizadas e vinculadas a uma fase, aguardando liberação de dependências técnicas. |
| **Ready** | `BLUE` | Tarefas com critérios de aceitação definidos e sem bloqueios, prontas para início imediato. |
| **In Progress** | `YELLOW` | Tarefas em desenvolvimento ativo. |
| **In Review / Validation** | `PURPLE` | Tarefas em revisão de código, execução de testes automatizados ou validação em dispositivos físicos. |
| **Done** | `GREEN` | Tarefas concluídas que cumpriram todos os critérios de aceitação. |

### 2.2. Campos Customizados do Project Board

| Campo | Tipo | Opções Configuradas |
|---|---|---|
| **Priority** | `SINGLE_SELECT` | `P0 - Crítica`, `P1 - Alta`, `P2 - Média`, `P3 - Baixa` |
| **Phase** | `SINGLE_SELECT` | `Fase 1: Fundação e Conectividade`, `Fase 2: Streaming e Controle`, `Fase 3: Webcam Virtual e Release` |
| **Subsystem** | `SINGLE_SELECT` | `Foundation / Infra`, `Protocol`, `Device Hub`, `File Hub`, `Clipboard Hub`, `Camera Hub`, `Screen Hub`, `Virtual Camera (macOS)`, `QA & Release` |

### 2.3. Labels Padronizadas no Repositório

- **Prioridade:** `priority:P0`, `priority:P1`, `priority:P2`, `priority:P3`
- **Fase:** `phase:1-foundation`, `phase:2-streaming`, `phase:3-distribution`
- **Subsistema:** `subsystem:foundation`, `subsystem:protocol`, `subsystem:device-hub`, `subsystem:file-hub`, `subsystem:clipboard-hub`, `subsystem:camera-hub`, `subsystem:screen-hub`, `subsystem:virtual-camera`, `subsystem:qa-release`
- **Plataforma:** `platform:android`, `platform:macos`, `platform:shared`

---

## 3. Catálogo de Tarefas, Prioridades e Dependências

| Ordem | Título da Issue | Prioridade | Fase | Subsistema | Status Inicial | Dependências Técnicas |
|---|---|---|---|---|---|---|
| **1** | `[Foundation] Estruturação do monorepositório e registro de ADRs iniciais` | `P0` | Fase 1 | `Foundation / Infra` | `Ready` | Nenhuma |
| **2** | `[Android] Configuração inicial do projeto Android (Clean Architecture, MVVM e Material 3)` | `P0` | Fase 1 | `Foundation / Infra` | `Ready` | Depende de #1 |
| **3** | `[macOS] Configuração inicial do cliente Nexus Desktop (SwiftUI e estrutura modular)` | `P0` | Fase 1 | `Foundation / Infra` | `Backlog` | Depende de #1 |
| **4** | `[Protocol] Definição do contrato de mensagens v1 e serialização multiplataforma` | `P0` | Fase 1 | `Protocol` | `Ready` | Depende de #1 |
| **5** | `[Device Hub] Descoberta de dispositivos na rede local via mDNS / DNS-SD` | `P0` | Fase 1 | `Device Hub` | `Backlog` | Depende de #2, #3 |
| **6** | `[Device Hub] Pareamento autenticado, chaves de confiança (Keystore) e persistência Room` | `P0` | Fase 1 | `Device Hub` | `Backlog` | Depende de #4, #5 |
| **7** | `[Device Hub] Máquina de estados da conexão, canal de controle TLS, heartbeat e reconexão` | `P0` | Fase 1 | `Device Hub` | `Backlog` | Depende de #6 |
| **8** | `[File Hub] Transferência bidirecional de arquivos sobre TCP/TLS com validação SHA-256` | `P1` | Fase 1 | `File Hub` | `Backlog` | Depende de #7 |
| **9** | `[Clipboard Hub] Sincronização segura de área de transferência textual entre Android e macOS` | `P1` | Fase 1 | `Clipboard Hub` | `Backlog` | Depende de #7 |
| **10** | `[Media Core] Integração WebRTC e sinalização pelo canal de controle autenticado` | `P1` | Fase 2 | `Camera Hub` | `Backlog` | Depende de #7 |
| **11** | `[Camera Hub] Streaming de câmera Android (Camera2 + H.264 HW) e janela de preview no macOS` | `P1` | Fase 2 | `Camera Hub` | `Backlog` | Depende de #10 |
| **12** | `[Screen Hub] Espelhamento de tela do Android via MediaProjection e WebRTC` | `P1` | Fase 2 | `Screen Hub` | `Backlog` | Depende de #10 |
| **13** | `[Camera Hub] Consulta de capacidades do sensor, controles manuais (ISO/Exposição/Zoom) e perfis` | `P2` | Fase 2 | `Camera Hub` | `Backlog` | Depende de #11 |
| **14** | `[Screen Hub] Mapeamento de coordenadas e controle remoto autorizado (AccessibilityService)` | `P2` | Fase 2 | `Screen Hub` | `Backlog` | Depende de #12 |
| **15** | `[Media Core] Monitoramento de latência ponta a ponta, taxa de quadros e adaptação de bitrate` | `P2` | Fase 2 | `QA & Release` | `Backlog` | Depende de #11, #12 |
| **16** | `[Virtual Camera] Extensão de câmera virtual no macOS com CoreMediaIO e Frame Bridge` | `P3` | Fase 3 | `Virtual Camera (macOS)` | `Backlog` | Depende de #11 |
| **17** | `[Transport] Suporte e otimização de transporte via USB Bridge e estabilidade prolongada` | `P3` | Fase 3 | `Device Hub` | `Backlog` | Depende de #7, #15 |
| **18** | `[Release & QA] Testes de integração multi-dispositivo, assinatura de artefatos e documentação final` | `P3` | Fase 3 | `QA & Release` | `Backlog` | Depende de #16, #17 |

---

## 4. Como Reproduzir a Configuração via GitHub CLI (`gh`)

### 4.1. Pré-requisitos

1. Ter a **GitHub CLI (`gh`)** e o utilitário **`jq`** instalados:
   ```bash
   brew install gh jq
   ```
2. Estar autenticado no GitHub com os escopos `repo` e `project`:
   ```bash
   gh auth status
   # Caso o escopo 'project' não esteja presente no token:
   gh auth refresh -h github.com -s project
   ```

### 4.2. Execução Automatizada via Script

O repositório inclui o script idempotente [`scripts/setup-backlog.sh`](../scripts/setup-backlog.sh), que executa toda a configuração de ponta a ponta (Labels, Milestones, Project Board, Colunas Kanban, Campos Customizados, Criação das 18 Issues e Preenchimento dos Cards):

```bash
chmod +x scripts/setup-backlog.sh
./scripts/setup-backlog.sh
```

### 4.3. Comandos Individuais da GitHub CLI (Referência Manual)

Caso deseje executar ou inspecionar as etapas individualmente:

#### 1. Criar e vincular o Project Board ao repositório
```bash
# Criar o projeto
gh project create --owner AnxeLOo --title "Nexus — Product Backlog" --format json

# Vincular ao repositório (substitua <NUMBER> pelo número do projeto)
gh project link <NUMBER> --owner AnxeLOo --repo AnxeLOo/project-nexus
```

#### 2. Criar campos customizados no Project Board
```bash
gh project field-create <NUMBER> --owner AnxeLOo \
  --name "Priority" --data-type "SINGLE_SELECT" \
  --single-select-options "P0 - Crítica,P1 - Alta,P2 - Média,P3 - Baixa"

gh project field-create <NUMBER> --owner AnxeLOo \
  --name "Phase" --data-type "SINGLE_SELECT" \
  --single-select-options "Fase 1: Fundação e Conectividade,Fase 2: Streaming e Controle,Fase 3: Webcam Virtual e Release"

gh project field-create <NUMBER> --owner AnxeLOo \
  --name "Subsystem" --data-type "SINGLE_SELECT" \
  --single-select-options "Foundation / Infra,Protocol,Device Hub,File Hub,Clipboard Hub,Camera Hub,Screen Hub,Virtual Camera (macOS),QA & Release"
```

#### 3. Configurar as colunas Kanban (opções do campo `Status`) via GraphQL
```bash
STATUS_FIELD_ID=$(gh project field-list <NUMBER> --owner AnxeLOo --format json --jq '.fields[] | select(.name == "Status") | .id')

gh api graphql -f query='
mutation UpdateStatusOptions($fieldId: ID!) {
  updateProjectV2Field(input: {
    fieldId: $fieldId,
    name: "Status",
    singleSelectOptions: [
      { name: "Backlog", color: GRAY, description: "Tarefas mapeadas aguardando refinamento ou liberação de dependências" },
      { name: "Ready", color: BLUE, description: "Tarefas desbloqueadas e prontas para desenvolvimento imediato" },
      { name: "In Progress", color: YELLOW, description: "Tarefas em implementação ativa" },
      { name: "In Review / Validation", color: PURPLE, description: "Tarefas em revisão de código ou validação em dispositivos" },
      { name: "Done", color: GREEN, description: "Tarefas concluídas com todos os critérios de aceitação validados" }
    ]
  }) {
    projectV2Field { ... on ProjectV2SingleSelectField { id name } }
  }
}' -f fieldId="$STATUS_FIELD_ID"
```

#### 4. Criar uma Issue e adicioná-la ao Project Board
```bash
ISSUE_URL=$(gh issue create \
  --repo AnxeLOo/project-nexus \
  --title "[Android] Configuração inicial do projeto Android (Clean Architecture, MVVM e Material 3)" \
  --body "Descrição e critérios de aceitação..." \
  --label "priority:P0,phase:1-foundation,subsystem:foundation,platform:android" \
  --milestone "Fase 1 — Fundação e MVP de Conectividade")

gh project item-add <NUMBER> --owner AnxeLOo --url "$ISSUE_URL"
```

#### 5. Inspecionar os recursos criados
```bash
# Listar todas as issues do backlog
gh issue list --repo AnxeLOo/project-nexus --limit 30

# Listar os campos e itens do Project Board
gh project field-list <NUMBER> --owner AnxeLOo
gh project item-list <NUMBER> --owner AnxeLOo --limit 30

# Abrir o Project Board no navegador
gh project view <NUMBER> --owner AnxeLOo --web
```

---

## 5. Ativação da Visualização Kanban (Board Layout) na Interface Web

No GitHub Projects V2, as colunas do quadro Kanban são governadas pelo campo **Status** (`Backlog`, `Ready`, `In Progress`, `In Review / Validation`, `Done`), já configurado pelo script. Para visualizar como **Board (Kanban)** no navegador:

1. Abra o projeto com `gh project view <NUMBER> --owner AnxeLOo --web`.
2. Na aba da visualização atual (`View 1`), clique no ícone de seta ao lado do nome da view e selecione o layout **Board** (Quadro).
3. Clique em **Save** para persistir o layout Kanban como visualização padrão do projeto.

