# Visão Geral do Produto e Premissas Técnicas — Nexus

> Este documento consolida a **Seção 1 (Visão geral do produto)** e a **Seção 2 (Premissas técnicas e limitações importantes)** da especificação arquitetural do **Nexus**.

---

## 1. Visão geral do produto

### 1.1. Nome e proposta de valor

**Nexus** é um aplicativo Android nativo que transforma o smartphone em uma extensão inteligente do Mac, permitindo integrar câmera, tela, arquivos, área de transferência e controles remotos em uma única solução.

O projeto será composto por dois sistemas complementares:

- **Nexus Android:** aplicativo nativo responsável por capturar imagens, transmitir vídeo, executar comandos autorizados, gerenciar arquivos e disponibilizar recursos do smartphone.
- **Nexus Desktop:** cliente e daemon para macOS responsável por receber os streams, controlar as sessões, gerenciar transferências e integrar os recursos do Android ao ambiente desktop.

O diferencial do projeto será a integração direta entre os dispositivos, priorizando baixa latência, segurança, desempenho e funcionamento na rede local, sem exigir que os dados sejam enviados a servidores externos.

### 1.2. Problema que o aplicativo resolve

A integração entre Android e macOS apresenta limitações quando o usuário precisa combinar funcionalidades que normalmente estão distribuídas entre diferentes aplicativos e soluções.

O Nexus pretende resolver quatro problemas principais:

1. **Fragmentação da integração:** reunir espelhamento de tela, controle remoto, transferência de arquivos e sincronização de clipboard em uma única plataforma.
2. **Limitações de videoconferência:** permitir que a câmera do smartphone funcione como uma fonte de vídeo de alta qualidade para aplicativos no Mac.
3. **Transferência de arquivos pouco integrada:** oferecer comunicação bidirecional com descoberta de dispositivos, pareamento seguro e transferências confiáveis.
4. **Dependência de serviços externos:** executar as principais operações diretamente entre os dispositivos, reduzindo dependências de infraestrutura na nuvem.

### 1.3. Público-alvo

| Público | Necessidade principal |
|---|---|
| Desenvolvedores de software | Testar aplicativos Android, inspecionar telas e controlar o dispositivo pelo Mac. |
| Criadores de conteúdo | Utilizar a câmera do smartphone em gravações e videoconferências. |
| Profissionais remotos | Compartilhar arquivos e integrar o smartphone ao fluxo de trabalho. |
| Usuários avançados | Automatizar tarefas e controlar dispositivos em uma rede local. |
| Fotógrafos e produtores de vídeo | Controlar parâmetros da câmera e utilizar o smartphone como fonte de vídeo. |

### 1.4. Funcionalidades principais

O produto será dividido em cinco subsistemas.

| Subsistema | Funcionalidades |
|---|---|
| **Screen Hub** | Espelhamento de tela, transmissão de vídeo e controle remoto por eventos de entrada. |
| **Camera Hub** | Captura de vídeo, streaming, controles manuais e seleção de resolução e taxa de quadros. |
| **File Hub** | Transferência bidirecional de arquivos, progresso, cancelamento e histórico. |
| **Clipboard Hub** | Sincronização de texto e compartilhamento de mídias leves. |
| **Device Hub** | Pareamento, descoberta, autenticação, heartbeat, reconexão e gerenciamento de sessões. |

O aplicativo deverá funcionar com três modos de conectividade:

- **USB:** opção prioritária para streaming com maior previsibilidade de latência, quando a implementação e os recursos disponíveis permitirem.
- **Wi-Fi:** opção principal para mobilidade, com descoberta e comunicação pela rede local.
- **Wi-Fi Direct:** alternativa para conexões diretas entre dispositivos compatíveis, quando oferecer vantagens sobre a infraestrutura de rede existente.

A seleção do transporte será independente dos módulos de negócio, permitindo alternar entre os meios de conexão sem reescrever a lógica de domínio.

---

## 2. Premissas técnicas e limitações importantes

Antes de definir a arquitetura, é necessário estabelecer três restrições que afetam diretamente a viabilidade do projeto.

### 2.1. Controle remoto do Android

Um aplicativo Android convencional não pode simular livremente toques em outros aplicativos apenas com permissões comuns.

Para implementar o controle remoto, será necessário avaliar duas alternativas:

- **AccessibilityService:** pode executar determinadas ações de acessibilidade e gestos autorizados pelo sistema. A viabilidade depende das APIs utilizadas, das restrições da versão do Android e das políticas aplicáveis à distribuição do aplicativo.
- **ADB ou integração privilegiada:** pode viabilizar formas mais abrangentes de controle em cenários de desenvolvimento, depuração ou dispositivos gerenciados, mas exige uma arquitetura e um processo de configuração diferentes.

A recomendação é desenvolver inicialmente um fluxo de controle baseado em um agente Android com permissões explícitas, avaliando separadamente os recursos que exigem ADB ou acesso privilegiado.

O Nexus não deve pressupor que um aplicativo comum conseguirá reproduzir todos os eventos de entrada em qualquer dispositivo.

### 2.2. Webcam virtual no macOS

Transmitir vídeo do Android para o Mac é diferente de disponibilizar esse vídeo como uma câmera selecionável em qualquer aplicativo.

A arquitetura deve distinguir dois recursos:

1. **Visualização de vídeo:** o cliente Nexus Desktop recebe e exibe o stream.
2. **Webcam virtual:** um componente específico do macOS disponibiliza o vídeo como fonte de câmera para aplicativos de terceiros.

Para o segundo recurso, a abordagem recomendada é investigar a API nativa de câmeras virtuais do macOS, utilizando um componente baseado em `CoreMediaIO` quando apropriado.

Isso evita tratar o recebimento de vídeo via WebRTC como se ele automaticamente criasse uma webcam disponível para outros aplicativos.

A compatibilidade com ferramentas como CamOps deverá ser validada separadamente, sem pressupor integração nativa.

### 2.3. Limites dos controles manuais da câmera

A API Camera2 permite consultar as capacidades de captura e configurar parâmetros manuais, mas os controles disponíveis variam conforme o hardware e a implementação do fabricante.

O Nexus deverá consultar as capacidades reais do dispositivo antes de expor cada controle.

| Controle | Estratégia |
|---|---|
| ISO | Configurar a sensibilidade por meio dos parâmetros de captura, quando suportado. |
| Velocidade do obturador | Configurar o tempo de exposição, respeitando os limites do sensor e a taxa de quadros. |
| Compensação de exposição | Ajustar a compensação em dispositivos que suportam o controle. |
| Zoom óptico | Utilizar as lentes e os níveis de zoom disponíveis no hardware. |
| Zoom digital | Ajustar a região de recorte da captura, conforme suportado. |
| Flash | Controlar o flash ou a tocha conforme o modo de captura e as capacidades do dispositivo. |

**Decisão arquitetural:** utilizar Camera2 como camada de controle avançado da câmera. CameraX poderá ser empregado para simplificar os fluxos de captura compatíveis, mas não deve ser tratado como substituto universal dos controles manuais de baixo nível.

Para requisitos estritos de ISO, exposição e integração com o encoder, uma implementação baseada diretamente em Camera2 pode oferecer o controle necessário.

---

## Próximas Leituras

- [Índice da Documentação (`docs/README.md`)](./README.md)
- [Arquitetura do Sistema (`docs/architecture/README.md`)](./architecture/README.md)
- [Protocolo e Estratégia de Comunicação (`docs/protocol/README.md`)](./protocol/README.md)
- [Roadmap e Priorização (`docs/roadmap.md`)](./roadmap.md)

