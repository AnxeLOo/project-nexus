# ADR-010: Controle Remoto do Android Baseado em Permissões Explícitas

- **Status:** Aceito
- **Data:** 2026-10-30
- **Subsistema:** Screen Hub / Remote Control (`platform:android`)

---

## 1. Contexto

O subsistema **Screen Hub** combina o espelhamento da tela do Android (`MediaProjection`) com a capacidade de interagir remotamente com o smartphone a partir do cliente **Nexus Desktop** no macOS (usando mouse, trackpad e teclado).

No modelo de segurança do sistema operacional Android, um aplicativo convencional instalado pelo usuário **não pode injetar eventos arbitrários de toque ou tecla em outros aplicativos** usando apenas permissões comuns de manifesto.

Existem duas abordagens técnicas distintas no ecossistema Android para realizar ações de entrada fora do próprio aplicativo:
1. **`AccessibilityService` (Serviço de Acessibilidade):** API oficial do Android que permite despachar gestos (`dispatchGesture`) e executar ações globais (Voltar, Home, Recentes, Notificações) mediante ativação manual e consentimento explícito do usuário nas Configurações de Acessibilidade do sistema.
2. **ADB (`input tap` / `scrcpy`-like server) ou acesso privilegiado/root:** Permite injeção abrangente de eventos em nível de shell (`shell` UID), mas exige que a Depuração USB/Wireless esteja ativa e requer um fluxo técnico de provisionamento via ADB.

---

## 2. Decisão

Implementar o controle remoto do **Nexus** com base em um **agente Android com permissões explícitas via `AccessibilityService`** (`platform:accessibility`), adotando as seguintes diretrizes arquiteturais e de experiência do usuário:

1. **Consentimento Explícito e Transparência:**
   O controle remoto só é habilitado se o usuário ativar conscientemente o serviço de acessibilidade do Nexus nas configurações do Android.
2. **Validação Contínua de Disponibilidade:**
   O aplicativo nunca deve presumir que conseguirá reproduzir qualquer evento de entrada em qualquer tela do sistema (por exemplo, telas protegidas pelo sistema operacional, prompts de permissão sensíveis ou telas de bloqueio seguras podem bloquear gestos sintéticos).
3. **Feedback Claro na Interface (Android e macOS):**
   Quando o `AccessibilityService` estiver desativado ou quando uma ação não puder ser executada por restrição de segurança do Android, a interface do Nexus Desktop e do Nexus Android deve informar claramente que o modo atual é **Somente Visualização (View-Only)** ou que a ação requer permissão explícita.
4. **Mapeamento Preciso de Coordenadas:**
   O cliente macOS converte eventos de ponteiro (toques discretos e gestos contínuos de arraste/rolagem) considerando resolução lógica do dispositivo, orientação atual (retrato/paisagem), área visível do stream e escala da janela antes de enviá-los pelo canal autenticado (`input.pointer` e `input.key`).
5. **Avaliação Separada de Integração via ADB:**
   Recursos avançados destinados exclusivamente a desenvolvedores via ADB poderão ser avaliados separadamente no futuro como uma extensão opcional de transporte/controle, sem comprometer a arquitetura padrão do aplicativo.

---

## 3. Consequências

### Positivas
- **Respeito à segurança do sistema operacional:** Funciona em dispositivos Android padrão sem exigir root nem configuração obrigatória de linha de comando (ADB) para o uso cotidiano via Wi-Fi.
- **Degradação graciosa:** Se o usuário optar por não conceder permissão de acessibilidade, o espelhamento de tela (`MediaProjection`) continua funcionando normalmente em modo de visualização.
- **Isolamento arquitetural:** Toda a lógica de `AccessibilityService` fica restrita ao módulo `platform:accessibility`, comunicando-se com o domínio por contratos claros.

### Trade-offs e Cuidados
- **Políticas de distribuição e privacidade:** O uso de `AccessibilityService` exige declaração transparente de finalidade ao usuário e não deve coletar nem transmitir conteúdo de tela textual via árvore de acessibilidade sem necessidade.
- **Limitações de gestos sintéticos:** Algumas janelas de sistema do Android rejeitam toques gerados por serviços de acessibilidade por proteção contra *tapjacking*; o protocolo deve retornar erro/aviso estruturado quando `dispatchGesture` for cancelado pelo sistema.

