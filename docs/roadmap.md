# Roadmap e Priorização do Desenvolvimento — Nexus

> Este documento consolida a **Seção 10 (As três fases do projeto)** e a **Seção 14 (Priorização do desenvolvimento)** da especificação arquitetural do **Nexus**.

---

## 1. As Três Fases do Projeto

Recomendo dividir o desenvolvimento em três fases, organizadas por redução de riscos técnicos.

A principal decisão é **validar primeiro a comunicação entre os dispositivos**, antes de investir na integração avançada da câmera e na extensão de câmera virtual.

### Fase 1 — Fundação e MVP de conectividade

**Objetivo:** provar que o Android e o macOS conseguem descobrir, parear e trocar dados de maneira confiável.

#### Escopo

- Estrutura do monorepositório.
- Configuração inicial dos projetos Android e macOS.
- Protocolo de comunicação versionado.
- Descoberta por mDNS.
- Pareamento seguro.
- Persistência de dispositivos pareados.
- Gerenciamento de conexão e reconexão.
- Transferência bidirecional de arquivos.
- Sincronização de clipboard textual.
- Histórico de transferências.
- Testes unitários do protocolo e da máquina de estados.

#### Critérios de conclusão

- Os dispositivos conseguem se descobrir e parear na mesma rede local.
- A comunicação é autenticada e criptografada.
- Arquivos transferidos passam pela verificação de integridade.
- A conexão consegue se recuperar de interrupções temporárias.
- O estado da conexão é refletido corretamente na interface.
- Os fluxos críticos possuem testes automatizados.

**Resultado esperado:** uma plataforma funcional de integração local, com arquitetura preparada para receber os subsistemas de mídia.

---

### Fase 2 — Streaming, câmera e controle remoto

**Objetivo:** transformar a comunicação básica em uma solução multimídia interativa.

#### Escopo

- Captura de tela com MediaProjection.
- Streaming de tela via WebRTC.
- Streaming de câmera com Camera2.
- Codificação H.264.
- Aceleração por hardware quando suportada.
- Visualização do vídeo no macOS.
- Controles manuais da câmera.
- Consulta de capacidades de cada dispositivo.
- Mapeamento de eventos de mouse e trackpad.
- Implementação do mecanismo autorizado de controle remoto.
- Monitoramento de latência, uso de CPU e consumo de bateria.

#### Critérios de conclusão

- O vídeo pode ser recebido e exibido no Mac.
- A latência é medida em condições controladas.
- Os controles da câmera respeitam as capacidades reais do hardware.
- O controle remoto funciona nos cenários de permissão explicitamente suportados.
- A interrupção da sessão encerra corretamente os recursos de captura.
- Os fluxos de mídia não bloqueiam as transferências de arquivos.

**Resultado esperado:** um MVP capaz de espelhar a tela, transmitir a câmera e executar ações remotas autorizadas.

---

### Fase 3 — Webcam virtual, otimização e distribuição

**Objetivo:** preparar o Nexus para uso cotidiano e distribuição.

#### Escopo

- Extensão de câmera virtual para macOS.
- Integração com o pipeline de vídeo do desktop.
- Otimização de buffers e consumo de memória.
- Ajuste de parâmetros de streaming conforme a rede.
- Melhorias de segurança e gerenciamento de dispositivos confiáveis.
- Testes de integração em diferentes modelos de Android.
- Testes de desempenho e estabilidade prolongada.
- Configuração de build variants.
- Assinatura de APK/AAB.
- Assinatura e empacotamento do aplicativo macOS.
- Documentação de instalação e recuperação de falhas.

#### Critérios de conclusão

- O Nexus pode ser selecionado como fonte de câmera em aplicativos compatíveis.
- Os testes de desempenho atendem às metas definidas para os dispositivos de referência.
- A extensão é instalada e ativada conforme os requisitos do macOS.
- O aplicativo consegue encerrar e recuperar sessões sem deixar recursos presos.
- Os artefatos de release são reproduzíveis e assinados adequadamente.
- A documentação permite instalar e configurar o produto sem depender do ambiente de desenvolvimento.

**Resultado esperado:** uma versão pronta para testes com usuários, com os principais recursos de integração e distribuição implementados.

---

## 2. Priorização do Desenvolvimento

Embora o produto tenha cinco subsistemas, eu não os desenvolveria simultaneamente.

A ordem recomendada é:

| Prioridade | Entrega | Motivo |
|---|---|---|
| P0 | Descoberta, pareamento e conexão segura | Estabelece a base para todas as outras funcionalidades. |
| P0 | Protocolo e gerenciamento de sessões | Evita duplicação de lógica entre os clientes. |
| P1 | Transferência de arquivos | Valida a comunicação bidirecional e a recuperação de falhas. |
| P1 | Streaming de câmera com preview no Mac | Valida o caminho de mídia antes da integração mais complexa. |
| P1 | Espelhamento de tela | Reutiliza o transporte de mídia, mas exige permissões e captura específicas. |
| P2 | Controles manuais avançados | Depende da validação das capacidades do hardware. |
| P2 | Controle remoto | Depende da estratégia de entrada autorizada e da experiência de uso. |
| P3 | Webcam virtual | Exige integração específica com o macOS. |
| P3 | Otimização avançada de USB e desempenho | Deve ser orientada pelos resultados das medições. |

A sincronização de clipboard textual pode ser desenvolvida durante a Fase 1, pois seu custo de implementação é relativamente baixo em comparação aos subsistemas de vídeo.

---

## Referências Relacionadas

- [Recomendação para a Primeira Implementação (`docs/recomendation.md`)](./recomendation.md)
- [Configuração do Backlog e GitHub Projects (`docs/backlog-setup.md`)](./backlog-setup.md)

