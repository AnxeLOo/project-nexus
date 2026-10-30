#!/usr/bin/env bash
# ==============================================================================
# Nexus — Script de Criação e Configuração do Product Backlog Inicial
# ==============================================================================
# Este script automatiza via GitHub CLI (gh):
#   1. Validação de autenticação e escopos (repo, project)
#   2. Criação/atualização de Labels padronizadas (Prioridade, Fase, Subsistema, Plataforma)
#   3. Criação de Milestones para as 3 fases do projeto
#   4. Criação das 18 GitHub Issues detalhadas com dependências e critérios de aceitação
#   5. Criação do GitHub Project Board ("Nexus — Product Backlog"), vínculo ao repositório,
#      configuração das colunas Kanban (Status), campos customizados (Priority, Phase, Subsystem)
#      e associação/classificação de todas as 18 Issues no quadro.
# ==============================================================================

set -euo pipefail

OWNER="${GITHUB_OWNER:-AnxeLOo}"
REPO_NAME="${GITHUB_REPO:-project-nexus}"
REPO="${OWNER}/${REPO_NAME}"
PROJECT_TITLE="${PROJECT_TITLE:-Nexus — Product Backlog}"

echo "=================================================================="
echo " Iniciando configuração do Product Backlog — ${REPO}"
echo "=================================================================="

# ------------------------------------------------------------------------------
# 1. Verificação de pré-requisitos e autenticação
# ------------------------------------------------------------------------------
if ! command -v gh >/dev/null 2>&1; then
  echo "Erro: GitHub CLI (gh) não encontrada. Instale com: brew install gh" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "Erro: 'jq' não encontrado. Instale com: brew install jq" >&2
  exit 1
fi

echo "-> Verificando autenticação no GitHub CLI..."
AUTH_STATUS="$(gh auth status 2>&1 || true)"
if ! echo "${AUTH_STATUS}" | grep -q "Logged in to github.com"; then
  echo "Erro: Você não está autenticado no GitHub CLI. Execute: gh auth login" >&2
  exit 1
fi

HAS_PROJECT_SCOPE="false"
if echo "${AUTH_STATUS}" | grep -q "'project'"; then
  HAS_PROJECT_SCOPE="true"
fi

# ------------------------------------------------------------------------------
# 2. Criação / Atualização de Labels
# ------------------------------------------------------------------------------
echo "-> Configurando Labels no repositório ${REPO}..."

create_label() {
  local name="$1"
  local color="$2"
  local desc="$3"
  gh label create "${name}" --repo "${REPO}" --color "${color}" --description "${desc}" --force >/dev/null
  echo "   [Label] ${name}"
}

# Prioridades
create_label "priority:P0" "B60205" "Prioridade crítica: bloqueante e fundacional para o projeto"
create_label "priority:P1" "D93F0B" "Prioridade alta: funcionalidade central do MVP"
create_label "priority:P2" "FBCA04" "Prioridade média: controles avançados, telemetria e refinamento"
create_label "priority:P3" "0E8A16" "Prioridade baixa: integrações avançadas de sistema, otimização e distribuição"

# Fases
create_label "phase:1-foundation" "1D76DB" "Fase 1 — Fundação e MVP de conectividade"
create_label "phase:2-streaming" "5319E7" "Fase 2 — Streaming, câmera e controle remoto"
create_label "phase:3-distribution" "006B75" "Fase 3 — Webcam virtual, otimização e distribuição"

# Subsistemas
create_label "subsystem:foundation" "C5DEF5" "Arquitetura base, monorepo, setup inicial e ADRs"
create_label "subsystem:protocol" "BFD4F2" "Contrato de mensagens versionado e serialização"
create_label "subsystem:device-hub" "D4C5F9" "Descoberta mDNS, pareamento, sessão TLS, heartbeat e reconexão"
create_label "subsystem:file-hub" "F9D0C4" "Transferência bidirecional de arquivos e verificação de integridade"
create_label "subsystem:clipboard-hub" "FEF2C0" "Sincronização segura de área de transferência"
create_label "subsystem:camera-hub" "C2E0C6" "Captura Camera2, codificação H.264, WebRTC e controles manuais"
create_label "subsystem:screen-hub" "BFDADC" "Espelhamento MediaProjection e controle remoto autorizado"
create_label "subsystem:virtual-camera" "E99695" "Extensão de câmera virtual CoreMediaIO no macOS"
create_label "subsystem:qa-release" "EDEDED" "Testes integrados, telemetria de desempenho, build variants e release"

# Plataformas
create_label "platform:android" "3DDC84" "Aplicativo nativo Android (Kotlin / Compose)"
create_label "platform:macos" "000000" "Cliente desktop e extensões nativas macOS (Swift / SwiftUI)"
create_label "platform:shared" "6F42C1" "Especificação, protocolo ou infraestrutura compartilhada"

# ------------------------------------------------------------------------------
# 3. Criação / Obtenção de Milestones
# ------------------------------------------------------------------------------
echo "-> Configurando Milestones no repositório ${REPO}..."

ensure_milestone() {
  local title="$1"
  local description="$2"
  local existing
  existing="$(gh api "repos/${REPO}/milestones?state=all" --jq ".[] | select(.title == \"${title}\") | .number" || true)"
  if [[ -n "${existing}" ]]; then
    echo "   [Milestone existente] #${existing} - ${title}" >&2
    echo "${existing}"
  else
    local created
    created="$(gh api "repos/${REPO}/milestones" -X POST -f title="${title}" -f description="${description}" --jq '.number')"
    echo "   [Milestone criada] #${created} - ${title}" >&2
    echo "${created}"
  fi
}

MS_PHASE1="$(ensure_milestone "Fase 1 — Fundação e MVP de Conectividade" "Provar que Android e macOS conseguem descobrir, parear e trocar dados de maneira confiável e segura na rede local.")"
MS_PHASE2="$(ensure_milestone "Fase 2 — Streaming, Câmera e Controle Remoto" "Transformar a comunicação básica em uma solução multimídia interativa com baixa latência (Camera2, MediaProjection, WebRTC e controle remoto autorizado).")"
MS_PHASE3="$(ensure_milestone "Fase 3 — Webcam Virtual, Otimização e Distribuição" "Integrar extensão de câmera virtual CoreMediaIO no macOS, otimizar transporte e preparar artefatos assinados para distribuição.")"

# ------------------------------------------------------------------------------
# 4. Criação e Configuração do GitHub Project Board (se escopo 'project' ativo)
# ------------------------------------------------------------------------------
PROJECT_NUMBER=""
PROJECT_ID=""
STATUS_FIELD_ID=""
PRIORITY_FIELD_ID=""
PHASE_FIELD_ID=""
SUBSYSTEM_FIELD_ID=""
FIELDS_JSON=""

if [[ "${HAS_PROJECT_SCOPE}" == "true" ]]; then
  echo "-> Configurando GitHub Project Board: '${PROJECT_TITLE}'..."

  EXISTING_PROJECT_JSON="$(gh project list --owner "${OWNER}" --format json --jq ".projects[] | select(.title == \"${PROJECT_TITLE}\")" || true)"

  if [[ -n "${EXISTING_PROJECT_JSON}" ]]; then
    PROJECT_NUMBER="$(echo "${EXISTING_PROJECT_JSON}" | jq -r '.number')"
    PROJECT_ID="$(echo "${EXISTING_PROJECT_JSON}" | jq -r '.id')"
    echo "   [Project existente] #${PROJECT_NUMBER} (${PROJECT_ID})"
  else
    CREATED_PROJECT_JSON="$(gh project create --owner "${OWNER}" --title "${PROJECT_TITLE}" --format json)"
    PROJECT_NUMBER="$(echo "${CREATED_PROJECT_JSON}" | jq -r '.number')"
    PROJECT_ID="$(echo "${CREATED_PROJECT_JSON}" | jq -r '.id')"
    echo "   [Project criado] #${PROJECT_NUMBER} (${PROJECT_ID})"
  fi

  gh project edit "${PROJECT_NUMBER}" --owner "${OWNER}" \
    --description "Product Backlog e Quadro Kanban para o desenvolvimento incremental do Nexus (Hub de integração entre Android e macOS)." \
    --readme "# Nexus — Product Backlog

Quadro Kanban oficial para acompanhamento do desenvolvimento incremental do **Nexus**.

## Fluxo de Trabalho (Colunas Kanban)
1. **Backlog**: Tarefas identificadas e priorizadas aguardando liberação de dependências.
2. **Ready**: Tarefas detalhadas, desbloqueadas e prontas para execução imediata.
3. **In Progress**: Tarefas em desenvolvimento ativo.
4. **In Review / Validation**: Em revisão técnica, execução de testes automatizados ou validação em dispositivos.
5. **Done**: Tarefas concluídas que atendem a todos os critérios de aceitação." >/dev/null

  echo "-> Vinculando Project #${PROJECT_NUMBER} ao repositório ${REPO}..."
  gh project link "${PROJECT_NUMBER}" --owner "${OWNER}" --repo "${REPO}" >/dev/null 2>&1 || true

  echo "-> Configurando colunas do Kanban (Status) e campos customizados..."
  FIELDS_JSON="$(gh project field-list "${PROJECT_NUMBER}" --owner "${OWNER}" --format json)"
  STATUS_FIELD_ID="$(echo "${FIELDS_JSON}" | jq -r '.fields[] | select(.name == "Status") | .id')"

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
      projectV2Field {
        ... on ProjectV2SingleSelectField {
          id
          name
        }
      }
    }
  }' -f fieldId="${STATUS_FIELD_ID}" >/dev/null

  ensure_single_select_field() {
    local field_name="$1"
    local options_csv="$2"
    local existing_id
    existing_id="$(echo "${FIELDS_JSON}" | jq -r ".fields[] | select(.name == \"${field_name}\") | .id")"
    if [[ -z "${existing_id}" || "${existing_id}" == "null" ]]; then
      gh project field-create "${PROJECT_NUMBER}" --owner "${OWNER}" \
        --name "${field_name}" \
        --data-type "SINGLE_SELECT" \
        --single-select-options "${options_csv}" >/dev/null
      echo "   [Campo criado] ${field_name}"
    else
      echo "   [Campo existente] ${field_name}"
    fi
  }

  ensure_single_select_field "Priority" "P0 - Crítica,P1 - Alta,P2 - Média,P3 - Baixa"
  ensure_single_select_field "Phase" "Fase 1: Fundação e Conectividade,Fase 2: Streaming e Controle,Fase 3: Webcam Virtual e Release"
  ensure_single_select_field "Subsystem" "Foundation / Infra,Protocol,Device Hub,File Hub,Clipboard Hub,Camera Hub,Screen Hub,Virtual Camera (macOS),QA & Release"

  FIELDS_JSON="$(gh project field-list "${PROJECT_NUMBER}" --owner "${OWNER}" --format json)"
  STATUS_FIELD_ID="$(echo "${FIELDS_JSON}" | jq -r '.fields[] | select(.name == "Status") | .id')"
  PRIORITY_FIELD_ID="$(echo "${FIELDS_JSON}" | jq -r '.fields[] | select(.name == "Priority") | .id')"
  PHASE_FIELD_ID="$(echo "${FIELDS_JSON}" | jq -r '.fields[] | select(.name == "Phase") | .id')"
  SUBSYSTEM_FIELD_ID="$(echo "${FIELDS_JSON}" | jq -r '.fields[] | select(.name == "Subsystem") | .id')"
else
  echo "-> [Aviso] Escopo 'project' ainda não habilitado no token atual."
  echo "   Criando Labels, Milestones e todas as 18 GitHub Issues agora."
  echo "   Para vincular ao Project Board em seguida, basta rodar no seu terminal:"
  echo "     gh auth refresh -h github.com -s project && ./scripts/setup-backlog.sh"
fi

get_option_id() {
  local field_name="$1"
  local option_name="$2"
  echo "${FIELDS_JSON}" | jq -r ".fields[] | select(.name == \"${field_name}\") | .options[] | select(.name == \"${option_name}\") | .id"
}

# ------------------------------------------------------------------------------
# 5. Função Auxiliar para Criar Issue e Associar ao Project Board
# ------------------------------------------------------------------------------
echo "-> Criando/verificando GitHub Issues do Product Backlog..."

EXISTING_ISSUES_JSON="$(gh issue list --repo "${REPO}" --state all --limit 100 --json number,title,url)"

create_backlog_item() {
  local title="$1"
  local body="$2"
  local labels="$3"
  local milestone_title="$4"
  local status_opt="$5"
  local priority_opt="$6"
  local phase_opt="$7"
  local subsystem_opt="$8"

  local issue_url
  issue_url="$(echo "${EXISTING_ISSUES_JSON}" | jq -r ".[] | select(.title == \"${title}\") | .url" | head -n 1)"

  if [[ -n "${issue_url}" && "${issue_url}" != "null" ]]; then
    echo "   [Issue existente] ${title} -> ${issue_url}" >&2
  else
    issue_url="$(gh issue create \
      --repo "${REPO}" \
      --title "${title}" \
      --body "${body}" \
      --label "${labels}" \
      --milestone "${milestone_title}")"
    echo "   [Issue criada] ${title} -> ${issue_url}" >&2
  fi

  if [[ "${HAS_PROJECT_SCOPE}" == "true" ]]; then
    local item_id
    item_id="$(gh project item-add "${PROJECT_NUMBER}" --owner "${OWNER}" --url "${issue_url}" --format json --jq '.id')"

    local status_opt_id priority_opt_id phase_opt_id subsystem_opt_id
    status_opt_id="$(get_option_id "Status" "${status_opt}")"
    priority_opt_id="$(get_option_id "Priority" "${priority_opt}")"
    phase_opt_id="$(get_option_id "Phase" "${phase_opt}")"
    subsystem_opt_id="$(get_option_id "Subsystem" "${subsystem_opt}")"

    gh project item-edit --id "${item_id}" --project-id "${PROJECT_ID}" --field-id "${STATUS_FIELD_ID}" --single-select-option-id "${status_opt_id}" >/dev/null
    gh project item-edit --id "${item_id}" --project-id "${PROJECT_ID}" --field-id "${PRIORITY_FIELD_ID}" --single-select-option-id "${priority_opt_id}" >/dev/null
    gh project item-edit --id "${item_id}" --project-id "${PROJECT_ID}" --field-id "${PHASE_FIELD_ID}" --single-select-option-id "${phase_opt_id}" >/dev/null
    gh project item-edit --id "${item_id}" --project-id "${PROJECT_ID}" --field-id "${SUBSYSTEM_FIELD_ID}" --single-select-option-id "${subsystem_opt_id}" >/dev/null
  fi

  echo "${issue_url##*/}"
}

MS1_TITLE="Fase 1 — Fundação e MVP de Conectividade"
MS2_TITLE="Fase 2 — Streaming, Câmera e Controle Remoto"
MS3_TITLE="Fase 3 — Webcam Virtual, Otimização e Distribuição"

# ==============================================================================
# FASE 1 — FUNDAÇÃO E MVP DE CONECTIVIDADE
# ==============================================================================

# Issue 1
I1_NUM="$(create_backlog_item \
  "[Foundation] Estruturação do monorepositório e registro de ADRs iniciais" \
  "## Objetivo
Estabelecer a organização de diretórios do monorepositório do **Nexus** (\`android/\`, \`macos/\`, \`protocol/\`, \`docs/\`, \`scripts/\`) e documentar as Decisões Arquiteturais (ADRs 001 a 010) que orientam o desenvolvimento incremental entre Android e macOS.

## Escopo Técnico
- Criar a estrutura de diretórios base conforme especificado na seção 8.1 do README:
  - \`android/\`, \`macos/\`, \`protocol/schemas/\`, \`protocol/examples/\`, \`docs/architecture/\`, \`docs/decisions/\`, \`docs/protocol/\`, \`docs/testing/\`, \`scripts/\`.
- Configurar o arquivo \`.gitignore\` global contemplando artefatos Android/Gradle, Xcode/SwiftPM, Kotlin, macOS (\`.DS_Store\`) e chaves locais.
- Registrar os documentos ADR iniciais em \`docs/decisions/\` (ADR-001 a ADR-010: Monorepositório, Clean Architecture + MVVM, WebRTC, Camera2, TCP/TLS, Room, CoreMediaIO, API de controle versionada, comunicação local direta e controle remoto baseado em permissões explícitas).

## Dependências
- Nenhuma (item fundacional do projeto).

## Critérios de Aceitação
- [ ] A árvore de diretórios do monorepositório está criada e documentada.
- [ ] O arquivo \`.gitignore\` previne o versionamento de builds locais, caches e credenciais.
- [ ] As decisões arquiteturais (ADR-001 a ADR-010) estão registradas em \`docs/decisions/\`.
- [ ] O \`README.md\` da pasta \`protocol/\` descreve a convenção para evolução dos schemas." \
  "priority:P0,phase:1-foundation,subsystem:foundation,platform:shared" \
  "${MS1_TITLE}" \
  "Ready" \
  "P0 - Crítica" \
  "Fase 1: Fundação e Conectividade" \
  "Foundation / Infra")"

# Issue 2
I2_NUM="$(create_backlog_item \
  "[Android] Configuração inicial do projeto Android (Clean Architecture, MVVM e Material 3)" \
  "## Objetivo
Configurar a estrutura inicial do projeto Android nativo do **Nexus** em \`android/\`, estabelecendo a base em Kotlin com Jetpack Compose, Material Design 3 (temas claro/escuro) e separação em camadas seguindo Clean Architecture e MVVM (conforme especificado em \`tasks/2_initial-setup.md\`).

## Escopo Técnico
- Configurar o projeto Gradle com Kotlin DSL e Version Catalog (\`libs.versions.toml\`).
- Configurar o SDK mínimo e target SDK, além das variantes de build \`debug\` e \`release\`.
- Implementar o sistema de design inicial em Material Design 3 com suporte a temas claro e escuro respeitando a preferência do sistema.
- Estruturar os pacotes/módulos em camadas **Presentation**, **Domain**, **Data** e **Platform Infrastructure**, garantindo que o domínio não dependa de classes Android, Room ou WebRTC.
- Configurar o ponto inicial de injeção de dependências.
- Criar uma tela inicial simples validando a configuração do projeto e a aplicação dos temas.
- Documentar no README as instruções para compilação e execução local do projeto Android.

## Dependências
- Depende de #${I1_NUM}

## Critérios de Aceitação
- [ ] O projeto Android está configurado com Kotlin e SDK mínimo adequado.
- [ ] O projeto compila e executa sem erros nas variantes \`debug\` e \`release\`.
- [ ] O Material Design 3 está configurado com suporte funcional aos temas claro e escuro.
- [ ] A estrutura inicial segue Clean Architecture e MVVM sem dependências indevidas entre apresentação, domínio e dados.
- [ ] A tela inicial demonstra a aplicação correta do tema e da identidade visual.
- [ ] A documentação de setup e execução local do projeto Android está atualizada." \
  "priority:P0,phase:1-foundation,subsystem:foundation,platform:android" \
  "${MS1_TITLE}" \
  "Ready" \
  "P0 - Crítica" \
  "Fase 1: Fundação e Conectividade" \
  "Foundation / Infra")"

# Issue 3
I3_NUM="$(create_backlog_item \
  "[macOS] Configuração inicial do cliente Nexus Desktop (SwiftUI e estrutura modular)" \
  "## Objetivo
Configurar a estrutura base do cliente **Nexus Desktop** para macOS em \`macos/\` utilizando Swift e SwiftUI, separando a interface gráfica (\`NexusApp\`), o núcleo de sessão/conectividade (\`NexusCore\`) e a suíte de testes (\`NexusTests\`).

## Escopo Técnico
- Criar o projeto/workspace macOS em Swift com suporte a SwiftUI.
- Estruturar os módulos internos:
  - \`NexusApp\`: Views SwiftUI, ViewModels e gerenciamento de janela de estado da sessão.
  - \`NexusCore\`: Abstrações de transporte, gerenciamento de sessão, modelos de domínio e serialização do protocolo.
  - \`NexusTests\`: Alvo de testes unitários para validação de regras de sessão e protocolo.
- Criar a janela inicial do aplicativo exibindo o estado atual da conexão (\`Disconnected\`) e área reservada para descoberta de dispositivos.
- Documentar os requisitos de versão do macOS/Xcode e comandos de build/test via linha de comando.

## Dependências
- Depende de #${I1_NUM}

## Critérios de Aceitação
- [ ] O projeto macOS compila sem erros via Xcode / \`swift build\`.
- [ ] A separação entre \`NexusApp\` (UI) e \`NexusCore\` (domínio/infraestrutura) está estabelecida.
- [ ] A tela inicial em SwiftUI renderiza corretamente o estado desconectado.
- [ ] O alvo \`NexusTests\` executa testes unitários básicos com sucesso." \
  "priority:P0,phase:1-foundation,subsystem:foundation,platform:macos" \
  "${MS1_TITLE}" \
  "Backlog" \
  "P0 - Crítica" \
  "Fase 1: Fundação e Conectividade" \
  "Foundation / Infra")"

# Issue 4
I4_NUM="$(create_backlog_item \
  "[Protocol] Definição do contrato de mensagens v1 e serialização multiplataforma" \
  "## Objetivo
Especificar o contrato de mensagens versionado (\`protocolVersion: 1\`) em \`protocol/\` e implementar a camada de serialização, validação e tratamento de erros em Kotlin (Android) e Swift (macOS).

## Escopo Técnico
- Definir o envelope padrão de mensagens (\`protocolVersion\`, \`messageId\`, \`sessionId\`, \`type\`, \`timestamp\`, \`payload\`) e respostas de confirmação/erro estruturado.
- Especificar os schemas e exemplos em \`protocol/schemas/\` e \`protocol/examples/\` para os comandos essenciais:
  - Sessão e saúde: \`session.start\`, \`session.stop\`, \`heartbeat\`, \`heartbeat.ack\`
  - Pareamento: negociação de identidade, desafio criptográfico e confirmação
  - Câmera e tela: \`camera.getCapabilities\`, \`camera.setControls\`, \`screen.start\`, \`screen.stop\`
  - Controle remoto: \`input.pointer\`, \`input.key\`
  - Transferência e clipboard: \`transfer.start\`, \`transfer.progress\`, \`transfer.cancel\`, \`clipboard.update\`
- Implementar serialização/desserialização em \`core:protocol\` (Android com Kotlin Serialization) e em \`NexusCore\` (macOS com \`Codable\`).
- Implementar validação de versão do protocolo, campos obrigatórios e limites de tamanho de payload.

## Dependências
- Depende de #${I1_NUM}

## Critérios de Aceitação
- [ ] Os schemas e exemplos JSON do protocolo v1 estão documentados em \`protocol/\`.
- [ ] As bibliotecas de protocolo no Android e no macOS serializam e desserializam todos os tipos de mensagem sem perda de dados.
- [ ] Mensagens malformadas ou com \`protocolVersion\` incompatível retornam erros estruturados previsíveis.
- [ ] Testes unitários validam a compatibilidade dos exemplos de \`protocol/examples/\` em ambas as plataformas." \
  "priority:P0,phase:1-foundation,subsystem:protocol,platform:shared" \
  "${MS1_TITLE}" \
  "Ready" \
  "P0 - Crítica" \
  "Fase 1: Fundação e Conectividade" \
  "Protocol")"

# Issue 5
I5_NUM="$(create_backlog_item \
  "[Device Hub] Descoberta de dispositivos na rede local via mDNS / DNS-SD" \
  "## Objetivo
Implementar o mecanismo de anúncio e descoberta de dispositivos na rede local utilizando mDNS / DNS-SD (Bonjour / NSD), permitindo que o Nexus Android e o Nexus Desktop se encontrem automaticamente sem depender de servidores externos.

## Escopo Técnico
- Definir o tipo de serviço DNS-SD do Nexus (ex.: \`_nexus-hub._tcp.\`) e os metadados TXT (identificador público efêmero, nome amigável, plataforma e versão do protocolo).
- **No macOS (\`NexusCore\`)**: publicar o serviço na rede local via \`Network.framework\` (\`NWListener\` / \`NetService\`) e descobrir dispositivos Android disponíveis.
- **No Android (\`platform:transport\` / \`feature:devices\`)**: implementar descoberta e resolução de endpoints via \`NsdManager\`, expondo um \`Flow\` reativo de dispositivos encontrados para a camada de domínio.
- Garantir que a descoberta seja tratada estritamente como localização de rede, exigindo etapa posterior de autenticação/pareamento.

## Dependências
- Depende de #${I2_NUM}, #${I3_NUM}

## Critérios de Aceitação
- [ ] O Nexus Desktop anuncia sua presença na rede local via mDNS/Bonjour.
- [ ] O Nexus Android lista em tempo real os computadores Mac descobertos na mesma rede local.
- [ ] O ciclo de vida da descoberta inicia e encerra corretamente sem vazamento de recursos de rede.
- [ ] A perda de anúncio ou saída do dispositivo da rede atualiza a lista na interface." \
  "priority:P0,phase:1-foundation,subsystem:device-hub,platform:shared" \
  "${MS1_TITLE}" \
  "Backlog" \
  "P0 - Crítica" \
  "Fase 1: Fundação e Conectividade" \
  "Device Hub")"

# Issue 6
I6_NUM="$(create_backlog_item \
  "[Device Hub] Pareamento autenticado, chaves de confiança (Keystore) e persistência Room" \
  "## Objetivo
Implementar o fluxo de pareamento seguro entre Android e macOS com verificação por código/QR Code, geração e armazenamento seguro de chaves (Android Keystore / macOS Keychain) e persistência local dos dispositivos pareados via Room.

## Escopo Técnico
- Implementar geração de par de chaves assimétricas por dispositivo no Android Keystore (\`core:security\`) e no Keychain do macOS.
- Desenvolver o protocolo de negociação de identidade com confirmação explícita do usuário (código numérico de verificação ou leitura de QR Code), proteção contra replay e expiração de desafios.
- Implementar as entidades persistentes no módulo \`core:database\` (Room) no Android e persistência correspondente no macOS:
  - \`PairedDevice\` (\`id\`, \`name\`, \`platform\`, \`publicKey\`, \`lastSeenAt\`, \`createdAt\`)
  - \`TrustedDeviceKey\` (\`deviceId\`, \`keyId\`, \`keyMaterialReference\`, \`createdAt\`, \`revokedAt\`)
  - \`AppSettings\` (\`id\`, \`preferredTransport\`, \`autoReconnect\`, \`clipboardSyncEnabled\`)
- Criar a tela de pareamento e listagem/revogação de dispositivos confiáveis em ambas as plataformas.

## Dependências
- Depende de #${I4_NUM}, #${I5_NUM}

## Critérios de Aceitação
- [ ] Dispositivos descobertos na rede não conseguem enviar comandos sem concluir o pareamento autenticado.
- [ ] Chaves privadas nunca são salvas em texto simples no banco de dados (uso obrigatório de Keystore/Keychain).
- [ ] O usuário consegue parear, visualizar dispositivos pareados e revogar a confiança de um dispositivo.
- [ ] Testes unitários e de integração validam a persistência no Room e a rejeição de desafios inválidos ou expirados." \
  "priority:P0,phase:1-foundation,subsystem:device-hub,platform:shared" \
  "${MS1_TITLE}" \
  "Backlog" \
  "P0 - Crítica" \
  "Fase 1: Fundação e Conectividade" \
  "Device Hub")"

# Issue 7
I7_NUM="$(create_backlog_item \
  "[Device Hub] Máquina de estados da conexão, canal de controle TLS, heartbeat e reconexão" \
  "## Objetivo
Implementar o canal de controle persistente sobre TLS entre dispositivos pareados, coordenado por uma máquina de estados centralizada com suporte a heartbeat e reconexão automática com backoff exponencial.

## Escopo Técnico
- Implementar a máquina de estados de conexão (\`Disconnected\`, \`Discovering\`, \`Pairing\`, \`Connecting\`, \`Connected\`, \`Reconnecting\`, \`Failed\`) com um único coordenador de transições.
- Estabelecer o canal de controle autenticado sobre TLS utilizando as credenciais dos dispositivos pareados.
- Implementar o envio periódico de \`heartbeat\` e validação de \`heartbeat.ack\` em escopo de Coroutines dedicado à conexão.
- Implementar a política de reconexão automática com backoff exponencial e jitter em caso de queda temporária de rede, revalidando a identidade antes de restaurar a sessão.
- Refletir o estado da conexão em tempo real nas interfaces do Android e do macOS.

## Dependências
- Depende de #${I6_NUM}

## Critérios de Aceitação
- [ ] A máquina de estados impede tentativas concorrentes de conexão e transições inválidas.
- [ ] O canal de controle utiliza TLS e rejeita conexões de dispositivos não confiáveis ou revogados.
- [ ] A perda de heartbeat transiciona a sessão para \`Reconnecting\` e restabelece a conexão automaticamente quando a rede retorna.
- [ ] Testes unitários com fakes (\`FakeConnectionRepository\`) cobrem todos os cenários de transição, timeout e reconexão." \
  "priority:P0,phase:1-foundation,subsystem:device-hub,platform:shared" \
  "${MS1_TITLE}" \
  "Backlog" \
  "P0 - Crítica" \
  "Fase 1: Fundação e Conectividade" \
  "Device Hub")"

# Issue 8
I8_NUM="$(create_backlog_item \
  "[File Hub] Transferência bidirecional de arquivos sobre TCP/TLS com validação SHA-256" \
  "## Objetivo
Implementar o subsistema **File Hub** para envio e recebimento de arquivos entre Android e macOS em um plano de dados dedicado (TCP/TLS), com acompanhamento de progresso em tempo real, cancelamento, escrita segura em arquivo temporário e verificação de integridade via SHA-256.

## Escopo Técnico
- Implementar o protocolo de transferência (\`transfer.start\`, \`transfer.progress\`, \`transfer.cancel\`) e o transporte em blocos sobre canal TCP/TLS separado do plano de mídia.
- Escrever os bytes recebidos em arquivo temporário e confirmar a conclusão somente após validar o hash SHA-256 completo do arquivo.
- Persistir o histórico de transferências na entidade \`TransferRecord\` (\`id\`, \`deviceId\`, \`fileName\`, \`sizeBytes\`, \`direction\`, \`status\`, \`createdAt\`) sem armazenar o binário no banco.
- Expor \`Flow<TransferProgress>\` para a interface exibir porcentagem, bytes transferidos e botão de cancelamento.
- Reconciliar transferências interrompidas por queda de conexão, marcando-as adequadamente sem considerá-las concluídas.

## Dependências
- Depende de #${I7_NUM}

## Critérios de Aceitação
- [ ] Arquivos podem ser enviados tanto do Android para o Mac quanto do Mac para o Android.
- [ ] O hash SHA-256 é validado no destino antes de mover o arquivo temporário para o local final.
- [ ] O usuário consegue acompanhar o progresso e cancelar uma transferência em andamento.
- [ ] Transferências corrompidas ou interrompidas não deixam arquivos parciais como concluídos e são registradas com status de falha/cancelamento no histórico." \
  "priority:P1,phase:1-foundation,subsystem:file-hub,platform:shared" \
  "${MS1_TITLE}" \
  "Backlog" \
  "P1 - Alta" \
  "Fase 1: Fundação e Conectividade" \
  "File Hub")"

# Issue 9
I9_NUM="$(create_backlog_item \
  "[Clipboard Hub] Sincronização segura de área de transferência textual entre Android e macOS" \
  "## Objetivo
Implementar o subsistema **Clipboard Hub** para compartilhamento de texto entre Android e macOS sobre o canal de dados confiável, respeitando as políticas de privacidade do sistema operacional e prevenindo loops de sincronização.

## Escopo Técnico
- Implementar envio e recebimento da mensagem \`clipboard.update\` para conteúdo textual com limite máximo de tamanho configurável.
- Garantir que o recurso venha desativado por padrão ou exija consentimento explícito por dispositivo pareado (\`AppSettings.clipboardSyncEnabled\`).
- Implementar detecção de origem/hash do último conteúdo aplicado para impedir ciclos infinitos de sincronização entre Android e Mac.
- Garantir que conteúdos do clipboard jamais sejam registrados em logs de depuração ou persistidos em banco de dados.
- Tratar adequadamente as restrições do Android para leitura de clipboard em segundo plano (sincronização quando o app estiver em foco ou por ação explícita).

## Dependências
- Depende de #${I7_NUM}

## Critérios de Aceitação
- [ ] A sincronização de clipboard pode ser ativada ou desativada individualmente nas configurações.
- [ ] Copiar um texto em um dispositivo atualiza o clipboard do dispositivo pareado sem gerar loop de reenvio.
- [ ] Payloads acima do limite configurado são rejeitados com aviso claro.
- [ ] Nenhum conteúdo do clipboard é gravado em logs ou armazenamento persistente." \
  "priority:P1,phase:1-foundation,subsystem:clipboard-hub,platform:shared" \
  "${MS1_TITLE}" \
  "Backlog" \
  "P1 - Alta" \
  "Fase 1: Fundação e Conectividade" \
  "Clipboard Hub")"

# ==============================================================================
# FASE 2 — STREAMING, CÂMERA E CONTROLE REMOTO
# ==============================================================================

# Issue 10
I10_NUM="$(create_backlog_item \
  "[Media Core] Integração WebRTC e sinalização pelo canal de controle autenticado" \
  "## Objetivo
Integrar a biblioteca WebRTC no Android (\`platform:webrtc\`) e no macOS (\`NexusCore\`), utilizando o canal de controle TLS existente para troca de mensagens de sinalização (SDP Offer/Answer e ICE Candidates) diretamente na rede local.

## Escopo Técnico
- Configurar as dependências do WebRTC no projeto Android e no cliente macOS.
- Estender o protocolo de controle para transportar mensagens de sinalização WebRTC (\`session.start\`, \`session.stop\`, oferta/resposta SDP e candidatos ICE) sobre a sessão autenticada.
- Configurar \`PeerConnection\` priorizando conexão direta em rede local (LAN/USB) sem necessidade de servidores TURN externos.
- Modelar a entidade de domínio transitória \`StreamingSession\` (\`sessionId\`, \`deviceId\`, \`streamType\`, \`resolution\`, \`frameRate\`, \`codec\`, \`startedAt\`).
- Garantir isolamento entre o plano de mídia (WebRTC) e o plano de dados (transferência de arquivos).

## Dependências
- Depende de #${I7_NUM}

## Critérios de Aceitação
- [ ] Dois dispositivos pareados conseguem negociar uma \`PeerConnection\` WebRTC usando apenas o canal de controle local.
- [ ] O encerramento da sessão libera todos os recursos nativos do WebRTC em ambas as plataformas.
- [ ] Falhas na negociação de mídia são reportadas à máquina de estados da sessão sem derrubar o canal de controle principal." \
  "priority:P1,phase:2-streaming,subsystem:camera-hub,platform:shared" \
  "${MS2_TITLE}" \
  "Backlog" \
  "P1 - Alta" \
  "Fase 2: Streaming e Controle" \
  "Camera Hub")"

# Issue 11
I11_NUM="$(create_backlog_item \
  "[Camera Hub] Streaming de câmera Android (Camera2 + H.264 HW) e janela de preview no macOS" \
  "## Objetivo
Implementar o pipeline de captura de vídeo da câmera do Android utilizando a API \`Camera2\` com codificação H.264 acelerada por hardware (\`MediaCodec\`), transmitindo via WebRTC para exibição em uma janela nativa de preview no **Nexus Desktop** (macOS).

## Escopo Técnico
- **No Android (\`platform:camera2\` e \`feature:camera\`)**:
  - Implementar captura com \`Camera2\` alimentando diretamente a \`Surface\` do encoder de hardware (\`MediaCodec\` H.264) e a fonte de vídeo do WebRTC, evitando cópias desnecessárias em CPU.
  - Suportar os perfis iniciais de resolução e taxa de quadros: 1920x1080 a 30 FPS (padrão) e 1280x720 a 60 FPS (quando suportado), além de alternância entre lente frontal e traseira.
  - Executar a captura em um \`ForegroundService\` apropriado para câmera, respeitando o ciclo de vida e as permissões do Android.
- **No macOS (\`NexusApp\` / \`NexusCore\`)**:
  - Receber a trilha de vídeo WebRTC e renderizar os frames com baixa latência usando \`AVFoundation\` / \`Metal\` em uma janela de visualização dedicada.

## Dependências
- Depende de #${I10_NUM}

## Critérios de Aceitação
- [ ] O vídeo da câmera do Android é exibido em tempo real na janela de preview do aplicativo macOS.
- [ ] O pipeline utiliza codificação H.264 acelerada por hardware quando disponível no dispositivo.
- [ ] O usuário consegue iniciar, pausar/encerrar o streaming e alternar entre câmera frontal e traseira.
- [ ] Encerrar o streaming ou desconectar o dispositivo desliga imediatamente a câmera no Android." \
  "priority:P1,phase:2-streaming,subsystem:camera-hub,platform:shared" \
  "${MS2_TITLE}" \
  "Backlog" \
  "P1 - Alta" \
  "Fase 2: Streaming e Controle" \
  "Camera Hub")"

# Issue 12
I12_NUM="$(create_backlog_item \
  "[Screen Hub] Espelhamento de tela do Android via MediaProjection e WebRTC" \
  "## Objetivo
Implementar o subsistema **Screen Hub** para captura e transmissão da tela do dispositivo Android utilizando \`MediaProjection\`, codificação H.264 por hardware e envio via WebRTC para visualização no macOS.

## Escopo Técnico
- Solicitar e gerenciar o consentimento explícito do usuário para captura de tela via \`MediaProjectionManager\`.
- Implementar o serviço em primeiro plano com \`foregroundServiceType=\"mediaProjection\"\`, atendendo aos requisitos das versões recentes do Android.
- Criar um \`VirtualDisplay\` conectado à \`Surface\` do encoder H.264 e publicar os frames na trilha de vídeo do WebRTC (\`screen.start\` / \`screen.stop\`).
- Tratar mudanças de orientação da tela (retrato/paisagem) e redimensionamento dinâmico na janela receptora do macOS.

## Dependências
- Depende de #${I10_NUM}

## Critérios de Aceitação
- [ ] O espelhamento inicia somente após autorização explícita do usuário no prompt do sistema Android.
- [ ] A tela do smartphone é renderizada com fluidez no cliente Nexus Desktop no macOS.
- [ ] A rotação do dispositivo atualiza corretamente a proporção de exibição no Mac.
- [ ] A interrupção pelo sistema ou pelo usuário encerra o \`VirtualDisplay\` e o serviço em primeiro plano sem vazamentos." \
  "priority:P1,phase:2-streaming,subsystem:screen-hub,platform:shared" \
  "${MS2_TITLE}" \
  "Backlog" \
  "P1 - Alta" \
  "Fase 2: Streaming e Controle" \
  "Screen Hub")"

# Issue 13
I13_NUM="$(create_backlog_item \
  "[Camera Hub] Consulta de capacidades do sensor, controles manuais (ISO/Exposição/Zoom) e perfis" \
  "## Objetivo
Implementar a inspeção real das capacidades de hardware da câmera via \`CameraCharacteristics\` e expor controles manuais remotos (ISO, velocidade do obturador, compensação de exposição, zoom óptico/digital e flash/tocha), permitindo salvar perfis na entidade \`CameraProfile\`.

## Escopo Técnico
- Implementar o modelo \`DeviceCapabilities\` consultando \`CameraCharacteristics\` no Android e enviando ao macOS via \`camera.getCapabilities\`.
- Expor na interface do Android e do macOS apenas os controles efetivamente suportados pelo sensor ativo:
  - Sensibilidade ISO (\`SENSOR_SENSITIVITY\`)
  - Tempo de exposição / obturador (\`SENSOR_EXPOSURE_TIME\`) respeitando a taxa de quadros
  - Compensação de exposição (\`CONTROL_AE_EXPOSURE_COMPENSATION\`)
  - Zoom óptico/digital (\`CONTROL_ZOOM_RATIO\` / região de recorte)
  - Flash / Tocha (\`FLASH_MODE_TORCH\`)
- Persistir configurações favoritas na entidade \`CameraProfile\` no Room, validando compatibilidade antes da aplicação.

## Dependências
- Depende de #${I11_NUM}

## Critérios de Aceitação
- [ ] O cliente macOS recebe e exibe apenas as faixas de ISO, exposição, resoluções e zoom suportadas pelo hardware do smartphone conectado.
- [ ] Alterações nos controles pelo Mac (\`camera.setControls\`) são aplicadas em tempo real na sessão \`Camera2\` e confirmadas via protocolo.
- [ ] Perfis de câmera (\`CameraProfile\`) podem ser salvos, carregados e validados contra as capacidades do dispositivo." \
  "priority:P2,phase:2-streaming,subsystem:camera-hub,platform:shared" \
  "${MS2_TITLE}" \
  "Backlog" \
  "P2 - Média" \
  "Fase 2: Streaming e Controle" \
  "Camera Hub")"

# Issue 14
I14_NUM="$(create_backlog_item \
  "[Screen Hub] Mapeamento de coordenadas e controle remoto autorizado (AccessibilityService)" \
  "## Objetivo
Implementar o fluxo de controle remoto do Android a partir da janela de espelhamento no macOS, convertendo eventos de mouse, trackpad e teclado em comandos autenticados do protocolo executados por um \`AccessibilityService\` explicitamente autorizado pelo usuário.

## Escopo Técnico
- **No macOS**: capturar eventos de clique, arraste (drag/swipe), rolagem e teclas sobre a janela de espelhamento, convertendo para coordenadas normalizadas considerando resolução lógica, orientação, barras/letterboxing e escala da janela.
- **No Protocolo**: enviar mensagens \`input.pointer\` e \`input.key\` sobre o canal autenticado.
- **No Android (\`platform:accessibility\` / \`feature:remotecontrol\`)**:
  - Implementar o adaptador de entrada baseado em \`AccessibilityService\` (\`dispatchGesture\` e ações globais como Voltar, Home, Recentes).
  - Exibir estado claro na interface quando a permissão de acessibilidade não estiver habilitada ou quando uma ação for restrita pelo sistema operacional.

## Dependências
- Depende de #${I12_NUM}

## Critérios de Aceitação
- [ ] Toques simples e gestos contínuos (arrastar/rolar) realizados no Mac são reproduzidos nas coordenadas exatas da tela do Android.
- [ ] O mapeamento de coordenadas permanece preciso após rotação da tela ou redimensionamento da janela no Mac.
- [ ] Caso o serviço de acessibilidade esteja desativado, a interface informa claramente a limitação e orienta como habilitar." \
  "priority:P2,phase:2-streaming,subsystem:screen-hub,platform:shared" \
  "${MS2_TITLE}" \
  "Backlog" \
  "P2 - Média" \
  "Fase 2: Streaming e Controle" \
  "Screen Hub")"

# Issue 15
I15_NUM="$(create_backlog_item \
  "[Media Core] Monitoramento de latência ponta a ponta, taxa de quadros e adaptação de bitrate" \
  "## Objetivo
Implementar instrumentação e telemetria em tempo real para medir latência de vídeo, FPS efetivo, frames descartados, bitrate e saúde da conexão, ajustando dinamicamente parâmetros de streaming sob degradação de rede.

## Escopo Técnico
- Registrar timestamps na captura do frame, codificação, envio RTP e renderização no receptor, compensando a diferença de relógio entre dispositivos para estimar a latência ponta a ponta (meta inicial: P95 < 150 ms em condições controladas).
- Coletar estatísticas do WebRTC (\`RTCStatsReport\`) para monitorar bitrate, perda de pacotes, jitter e FPS efetivo.
- Implementar política de adaptação dinâmica (redução de bitrate, FPS ou resolução) quando houver congestionamento na rede local, evitando filas longas de frames.
- Verificar que transferências simultâneas no **File Hub** não degradem a estabilidade da sessão de vídeo além dos limites operacionais.

## Dependências
- Depende de #${I11_NUM}, #${I12_NUM}

## Critérios de Aceitação
- [ ] O painel de diagnóstico exibe métricas em tempo real de FPS, resolução, bitrate e latência estimada.
- [ ] O pipeline evita acúmulo de atraso (bufferbloat) reduzindo taxa de bits/quadros durante oscilações de rede.
- [ ] Uma transferência de arquivo em andamento não interrompe nem bloqueia a transmissão de vídeo." \
  "priority:P2,phase:2-streaming,subsystem:qa-release,platform:shared" \
  "${MS2_TITLE}" \
  "Backlog" \
  "P2 - Média" \
  "Fase 2: Streaming e Controle" \
  "QA & Release")"

# ==============================================================================
# FASE 3 — WEBCAM VIRTUAL, OTIMIZAÇÃO E DISTRIBUIÇÃO
# ==============================================================================

# Issue 16
I16_NUM="$(create_backlog_item \
  "[Virtual Camera] Extensão de câmera virtual no macOS com CoreMediaIO e Frame Bridge" \
  "## Objetivo
Desenvolver o módulo \`NexusCameraExtension\` para macOS baseado em \`CoreMediaIO\`, disponibilizando o stream de vídeo recebido do Android como uma webcam virtual selecionável em aplicativos de terceiros (FaceTime, Meet, Zoom, OBS).

## Escopo Técnico
- Criar o target \`NexusCameraExtension\` utilizando a API moderna de Camera Extension do \`CoreMediaIO\` (Provider, Device e Stream Source).
- Implementar o componente **Frame Bridge** (IPC / compartilhamento eficiente de buffers de vídeo) entre o cliente \`NexusDesktop\` e a extensão \`CoreMediaIO\`.
- Converter os frames decodificados para o formato de pixel compatível esperado pela extensão mantendo baixa utilização de CPU/memória.
- Implementar no aplicativo macOS o fluxo de instalação, ativação (\`SystemExtensions\`) e verificação de status/aprovação da extensão pelo usuário.

## Dependências
- Depende de #${I11_NUM}

## Critérios de Aceitação
- [ ] A câmera virtual do Nexus aparece listada como dispositivo de entrada de vídeo nos aplicativos do macOS.
- [ ] Os frames transmitidos pelo Android são exibidos na webcam virtual com estabilidade e baixa latência.
- [ ] Quando não há sessão ativa, a extensão exibe um frame placeholder informativo sem travar o aplicativo consumidor." \
  "priority:P3,phase:3-distribution,subsystem:virtual-camera,platform:macos" \
  "${MS3_TITLE}" \
  "Backlog" \
  "P3 - Baixa" \
  "Fase 3: Webcam Virtual e Release" \
  "Virtual Camera (macOS)")"

# Issue 17
I17_NUM="$(create_backlog_item \
  "[Transport] Suporte e otimização de transporte via USB Bridge e estabilidade prolongada" \
  "## Objetivo
Implementar o adaptador de transporte sobre conexão cabeada USB (USB Bridge / port forwarding ou canal direto) como alternativa de latência previsível ao Wi-Fi, garantindo alternância transparente para os módulos de domínio.

## Escopo Técnico
- Implementar detecção e estabelecimento de conexão local via USB no \`Transport Adapter\` sem alterar as regras de negócio de \`Camera Hub\`, \`Screen Hub\` ou \`File Hub\`.
- Permitir configurar a preferência de transporte em \`AppSettings.preferredTransport\` (USB prioritário ou Wi-Fi).
- Executar testes comparativos de latência, jitter e estabilidade de longa duração entre USB e Wi-Fi 5 GHz.
- Otimizar alocação de buffers, consumo de memória e comportamento térmico durante sessões contínuas de streaming.

## Dependências
- Depende de #${I7_NUM}, #${I15_NUM}

## Critérios de Aceitação
- [ ] A camada de transporte estabelece sessão autenticada via USB mantendo o mesmo contrato de protocolo usado no Wi-Fi.
- [ ] A medição de latência via USB apresenta previsibilidade e atende à meta P95 < 150 ms.
- [ ] Sessões prolongadas de streaming não apresentam vazamento progressivo de memória (memory leak)." \
  "priority:P3,phase:3-distribution,subsystem:device-hub,platform:shared" \
  "${MS3_TITLE}" \
  "Backlog" \
  "P3 - Baixa" \
  "Fase 3: Webcam Virtual e Release" \
  "Device Hub")"

# Issue 18
I18_NUM="$(create_backlog_item \
  "[Release & QA] Testes de integração multi-dispositivo, assinatura de artefatos e documentação final" \
  "## Objetivo
Consolidar a suíte de testes de integração e desempenho, configurar a geração e assinatura dos artefatos de release para Android (APK/AAB) e macOS (App Bundle + System Extension) e finalizar a documentação de instalação e operação.

## Escopo Técnico
- Validar a suíte de testes automatizados (unitários, integração de protocolo Kotlin/Swift, persistência Room, segurança e UI nos fluxos críticos).
- Configurar no Android o build \`release\` com R8/ProGuard, Baseline Profiles e assinatura segura via variáveis de ambiente (sem expor chaves no repositório).
- Configurar no macOS o empacotamento, entitlements e assinatura do aplicativo \`NexusDesktop\` e da extensão \`NexusCameraExtension\`.
- Elaborar o guia completo de instalação, solução de problemas (troubleshooting de permissões e rede local) e recuperação de falhas em \`docs/\`.

## Dependências
- Depende de #${I16_NUM}, #${I17_NUM}

## Critérios de Aceitação
- [ ] Todos os testes unitários e de integração dos fluxos críticos executam com sucesso.
- [ ] Os artefatos de release do Android (APK/AAB) e do macOS são gerados de forma reproduzível e sem credenciais hardcoded.
- [ ] A documentação permite instalar, parear e utilizar o Nexus sem depender do ambiente de desenvolvimento." \
  "priority:P3,phase:3-distribution,subsystem:qa-release,platform:shared" \
  "${MS3_TITLE}" \
  "Backlog" \
  "P3 - Baixa" \
  "Fase 3: Webcam Virtual e Release" \
  "QA & Release")"

echo "=================================================================="
if [[ "${HAS_PROJECT_SCOPE}" == "true" ]]; then
  echo " Product Backlog configurado com sucesso!"
  echo " Project Board #${PROJECT_NUMBER}: ${PROJECT_TITLE}"
  echo " Visualize no navegador com:"
  echo "   gh project view ${PROJECT_NUMBER} --owner ${OWNER} --web"
else
  echo " Labels, Milestones e todas as 18 GitHub Issues foram criadas!"
  echo " Falta apenas autorizar o escopo 'project' no seu terminal:"
  echo "   gh auth refresh -h github.com -s project"
  echo " e executar novamente:"
  echo "   ./scripts/setup-backlog.sh"
fi
echo "=================================================================="
