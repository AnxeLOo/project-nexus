package com.nexus.feature.dashboard.ui

import com.nexus.core.model.ConnectionState
import com.nexus.core.model.NexusSubsystemStatus
import com.nexus.core.model.ThemePreference
import com.nexus.core.model.TransportType

/**
 * Estado imutável da tela inicial (Dashboard) do Nexus.
 */
data class DashboardUiState(
    val isLoading: Boolean = true,
    val appVersion: String = "0.1.0-foundation",
    val protocolVersion: Int = 1,
    val connectionState: ConnectionState = ConnectionState.DISCONNECTED,
    val preferredTransport: TransportType = TransportType.WIFI,
    val supportedTransports: List<TransportType> = TransportType.entries,
    val subsystems: List<NexusSubsystemStatus> = emptyList(),
    val themePreference: ThemePreference = ThemePreference.SYSTEM
)

