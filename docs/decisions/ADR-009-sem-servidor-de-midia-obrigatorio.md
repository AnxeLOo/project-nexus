# ADR-009: Comunicação Local Direta sem Servidor de Mídia ou Nuvem Obrigatório

- **Status:** Aceito
- **Data:** 2026-10-30
- **Subsistema:** Device Hub / Transport (`platform:shared`)

---

## 1. Contexto

Muitas soluções de integração entre dispositivos móveis e computadores dependem de contas na nuvem, servidores externos de sinalização ou servidores intermediários de retransmissão (TURN/relays remotos) para conectar os dispositivos do usuário.

Essa dependência externa gera quatro problemas que o **Nexus** se propõe a resolver:
1. **Aumento de latência e consumo de banda externa:** Enviar vídeo 1080p/60fps ou arquivos grandes para a internet apenas para entregá-los a um computador que está na mesma mesa degradaria a latência e a qualidade.
2. **Riscos de privacidade:** O fluxo da câmera, a tela do smartphone, os arquivos pessoais e o conteúdo da área de transferência contêm dados altamente sensíveis que não devem transitar por servidores de terceiros.
3. **Indisponibilidade offline:** O usuário não conseguiria usar o aplicativo em ambientes sem acesso à internet externa ou com restrições corporativas de firewall para a nuvem.
4. **Custo de infraestrutura contínua:** Manter servidores de mídia em nuvem adicionaria custos operacionais e pontos únicos de falha ao projeto.

---

## 2. Decisão

Arquitetar o **Nexus** para operar de forma **100% local e direta (peer-to-peer)** entre o Android e o macOS, sem exigir backend em nuvem nem servidor externo de mídia ou sinalização:

1. **Descoberta Local via mDNS / DNS-SD:**
   Os dispositivos se descobrem diretamente na rede local utilizando Bonjour (`Network.framework` no macOS) e NSD (`NsdManager` no Android).
2. **Pareamento e Autenticação Diretos:**
   A confiança entre os dispositivos é estabelecida localmente mediante criptografia de chave pública e confirmação visual pelo usuário (código numérico ou QR Code), persistindo as credenciais nos dispositivos ([ADR-006](./ADR-006-room-para-dados-locais.md)).
3. **Sinalização WebRTC pelo Canal Local:**
   A troca de ofertas/respostas SDP e candidatos ICE do WebRTC utiliza o próprio **Plano de Controle TLS local** estabelecido entre o Android e o Mac ([ADR-003](./ADR-003-webrtc-para-midia.md)), dispensando servidores de sinalização na internet.
4. **Abstração do Meio Físico de Transporte:**
   A camada de transporte (`platform:transport` e `NexusCore`) é desacoplada das regras de domínio para suportar **Wi-Fi / LAN**, **USB** (para máxima previsibilidade de latência) e **Wi-Fi Direct** quando aplicável.

---

## 3. Consequências

### Positivas
- **Privacidade por design (Privacy by Design):** Vídeo da câmera, tela, arquivos e clipboard nunca saem do ambiente local do usuário.
- **Desempenho e baixa latência:** O tráfego percorre o caminho mais curto possível (rede local Wi-Fi 5GHz/6GHz ou cabo USB).
- **Zero custo de infraestrutura em nuvem:** O sistema funciona de forma autônoma entre o par Android e Mac.

### Trade-offs e Cuidados
- **Restrições em redes com Client Isolation (AP Isolation):** Em redes Wi-Fi públicas ou corporativas que bloqueiam comunicação direta entre clientes (ou bloqueiam multicast mDNS), a descoberta via Wi-Fi pode não funcionar, tornando importante o suporte alternativo por conexão direta (USB / endereço direto / Wi-Fi Direct).
- **Descoberta ≠ Autenticação:** Como qualquer dispositivo na mesma LAN pode anunciar registros mDNS, o Nexus jamais deve confiar em um dispositivo apenas por tê-lo descoberto na rede; o pareamento criptográfico e o handshake TLS são obrigatórios antes de qualquer operação.

