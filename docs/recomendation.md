# Minha recomendação para a primeira implementação

Começaria com um experimento técnico pequeno, com apenas quatro entregas:

- Descoberta e pareamento entre Android e macOS.
- Conexão autenticada com um protocolo de controle versionado.
- Transmissão de vídeo da câmera do Android para uma janela nativa do Mac.
- Transferência de um arquivo com verificação de integridade.

Esse experimento deverá responder às principais incertezas do projeto: a qualidade da conexão local, a viabilidade do pipeline de vídeo, a compatibilidade dos dispositivos e a complexidade de manter uma sessão estável.

**A decisão mais importante é não começar pela webcam virtual nem pelo controle remoto completo.** Primeiro, valide a comunicação entre as plataformas. Depois, implemente os recursos de mídia e, por último, as integrações de sistema mais complexas.

Isso reduz o risco de investir em funcionalidades avançadas antes de provar que o núcleo do Nexus é confiável, seguro e suficientemente rápido.