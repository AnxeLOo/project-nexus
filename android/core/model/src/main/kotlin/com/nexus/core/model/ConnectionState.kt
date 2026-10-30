package com.nexus.core.model

/**
 * Representa a máquina de estados da sessão de conectividade entre o Android e o macOS,
 * conforme definido na seção 4.2 e 9.2 da especificação arquitetural.
 *
 * Este modelo pertence ao domínio puro e não possui dependências do framework Android.
 */
enum class ConnectionState {
    DISCONNECTED,
    DISCOVERING,
    PAIRING,
    CONNECTING,
    CONNECTED,
    RECONNECTING,
    FAILED
}

