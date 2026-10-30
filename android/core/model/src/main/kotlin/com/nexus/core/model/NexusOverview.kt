package com.nexus.core.model

/**
 * Visão geral do estado arquitetural e de ambiente do aplicativo Nexus.
 * Utilizado pela camada de apresentação para validar o fluxo reativo MVVM + Clean Architecture.
 */
data class NexusOverview(
    val appVersion: String,
    val protocolVersion: Int,
    val connectionState: ConnectionState,
    val preferredTransport: TransportType,
    val supportedTransports: List<TransportType>,
    val subsystems: List<NexusSubsystemStatus>,
    val themePreference: ThemePreference
)

