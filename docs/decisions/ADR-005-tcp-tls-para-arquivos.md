# ADR-005: Transporte TCP/TLS Dedicado para Transferência de Arquivos

- **Status:** Aceito
- **Data:** 2026-10-30
- **Subsistema:** File Hub (`platform:shared`)

---

## 1. Contexto

O subsistema **File Hub** permite transferir arquivos bidirecionalmente entre Android e macOS na rede local. Ao contrário do streaming de vídeo (onde descartar um frame atrasado é preferível a travar a reprodução), a transferência de arquivos exige:
- Entrega ordenada e sem perda de bytes;
- Verificação estrita de integridade ponta a ponta (hash **SHA-256**);
- Controle de fluxo (backpressure) para não saturar a memória RAM em arquivos grandes;
- Observabilidade de progresso (`Flow<TransferProgress>`) e suporte a cancelamento imediato;
- **Isolamento de tráfego:** Enviar um arquivo grande não pode bloquear o envio de comandos de controle nem degradar severamente a transmissão de vídeo da câmera/tela.

---

## 2. Decisão

Implementar a transferência de arquivos sobre um **canal TCP autenticado e criptografado com TLS (Plano de Dados)**, separado logicamente e em nível de socket/stream do Plano de Controle e do Plano de Mídia (WebRTC):

1. **Coordenação pelo Plano de Controle:** O início, metadados (nome, tamanho, hash SHA-256 esperado), progresso e cancelamento são sinalizados por mensagens tipadas (`transfer.start`, `transfer.progress`, `transfer.cancel`).
2. **Transmissão em blocos sobre TCP/TLS:** O conteúdo binário do arquivo é transmitido em blocos (*chunks*) de tamanho controlado sobre uma conexão TCP/TLS dedicada.
3. **Escrita atômica via arquivo temporário:** O receptor grava os blocos recebidos em um arquivo temporário local.
4. **Validação SHA-256 antes da confirmação:** Ao receber todos os bytes, o receptor calcula o hash SHA-256 do arquivo temporário. Somente se o hash coincidir com o anunciado nos metadados o arquivo é movido para o destino final e o registro `TransferRecord` é marcado como concluído.
5. **Reconciliação em falhas de rede:** Se a conexão cair durante uma transferência, o restabelecimento da sessão (reconexão) **não** marca a transferência interrompida como concluída; seu estado é reconciliado como falha/interrompida e o arquivo temporário incompleto é descartado (ou preparado para retomada explícita futura).

---

## 3. Consequências

### Positivas
- **Confiabilidade e simplicidade:** O TCP gerencia nativamente ordenação, retransmissão e controle de fluxo para grandes volumes de bytes, enquanto o TLS garante confidencialidade e autenticidade na rede local.
- **Proteção contra arquivos corrompidos:** O uso combinado de arquivo temporário + validação SHA-256 garante que o usuário nunca receba um arquivo truncado como se estivesse íntegro.
- **Não interferência no Plano de Controle e Mídia:** Evita *head-of-line blocking* nas mensagens críticas de sessão, câmera, entrada remota e heartbeat.

### Trade-offs e Cuidados
- **Gerenciamento de conexões adicionais:** O cliente e o daemon devem coordenar a abertura, autenticação por token/sessão e fechamento seguro do socket de transferência associado à sessão ativa.
- **Limites e espaço em disco:** O receptor deve validar espaço disponível e limites máximos configuráveis antes de aceitar o início da transferência (`transfer.start`).

