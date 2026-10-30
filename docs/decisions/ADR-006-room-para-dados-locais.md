# ADR-006: Persistência Local com Room e Separação de Segredos no Keystore

- **Status:** Aceito
- **Data:** 2026-10-30
- **Subsistema:** Device Hub / Data Layer (`platform:android`)

---

## 1. Contexto

O aplicativo **Nexus Android** precisa persistir dados estruturados entre execuções do aplicativo:
- Dispositivos pareados (`PairedDevice`);
- Histórico de conexões relevantes (`DeviceConnection`);
- Perfis de configuração de câmera (`CameraProfile`);
- Histórico de transferências de arquivos (`TransferRecord`);
- Preferências globais (`AppSettings`);
- Metadados e referências de chaves de dispositivos confiáveis (`TrustedDeviceKey`).

Ao mesmo tempo, o sistema lida com dois tipos de dados que **não** devem ser gravados diretamente no banco relacional:
1. **Material criptográfico privado (chaves privadas do dispositivo):** Armazenar chaves privadas em texto simples no SQLite violaria os requisitos de segurança da plataforma.
2. **Estados transitórios de alta frequência (`StreamingSession`, progresso byte a byte em tempo real, heartbeats contínuos):** Gravar cada atualização de frame ou pacote no banco geraria contenção de I/O e desgaste desnecessário.

---

## 2. Decisão

Utilizar a biblioteca oficial **Room Persistence Library** no módulo `core:database` para persistência local estruturada no Android, combinada com as seguintes diretrizes de arquitetura de dados:

1. **Entidades persistentes no Room:**
   - `PairedDevice`: Metadados e chave pública dos computadores Mac pareados.
   - `TrustedDeviceKey`: Controle de identidade, referência ao alias da chave e status de revogação (`revokedAt`).
   - `DeviceConnection`: Registro histórico de conexões estabelecidas.
   - `CameraProfile`: Presets salvos pelo usuário (validados contra `DeviceCapabilities` antes do uso).
   - `TransferRecord`: Metadados do histórico de transferências (sem armazenar o conteúdo binário dos arquivos no banco).
   - `AppSettings`: Configurações de transporte preferencial, reconexão automática e permissão de sincronização de clipboard.
2. **Proteção de chaves no Android Keystore (`core:security`):**
   - A chave privada do dispositivo Android deve ser gerada e mantida exclusivamente no **Android Keystore** (e no **Keychain** no caso do macOS). O banco de dados armazena apenas identificadores/referências (`keyMaterialReference`) e chaves públicas.
3. **Estados transitórios em memória:**
   - `StreamingSession`, `ConnectionState` ativo e `TransferProgress` em andamento permanecem em memória (expostos via `StateFlow` pelos repositórios), atualizando o Room apenas em marcos relevantes de ciclo de vida (início, conclusão, falha ou desconexão).
4. **Proibição de persistência de Clipboard:**
   - Conteúdos sincronizados pelo **Clipboard Hub** jamais devem ser persistidos no Room ou registrados em logs.

---

## 3. Consequências

### Positivas
- **Consultas reativas e seguras em tempo de compilação:** Room oferece verificação estática de SQL e integração nativa com Kotlin `Coroutines` e `Flow`.
- **Segurança criptográfica:** Chaves privadas permanecem protegidas por hardware (TEE/StrongBox quando disponível no aparelho).
- **Desempenho preservado:** Evita operações de disco desnecessárias durante sessões intensivas de streaming ou transferência.

### Trade-offs e Cuidados
- **Gestão de migrações de schema:** Evoluções nas tabelas do Room exigem definição explícita de `Migration` (ou AutoMigration) e testes instrumentados de migração no módulo `core:database`.
- **Desacoplamento do domínio:** Entidades anotadas com `@Entity` pertencem exclusivamente à camada `Data` (`core:database`) e devem ser convertidas para modelos puros antes de chegar à camada `Domain`.

