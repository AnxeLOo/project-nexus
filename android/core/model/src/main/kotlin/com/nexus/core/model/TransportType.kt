package com.nexus.core.model

/**
 * Modos de conectividade física/lógica suportados pela camada de transporte do Nexus.
 * A seleção do transporte é independente das regras de negócio dos subsistemas.
 */
enum class TransportType(val displayName: String, val badgeLabel: String) {
    USB(displayName = "USB (Baixa Latência)", badgeLabel = "USB"),
    WIFI(displayName = "Wi-Fi Local (mDNS/TLS)", badgeLabel = "Wi-Fi 5G"),
    WIFI_DIRECT(displayName = "Wi-Fi Direct (P2P)", badgeLabel = "P2P")
}

