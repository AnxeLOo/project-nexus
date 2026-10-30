package com.nexus.core.testing.repository

import com.nexus.core.domain.repository.NexusOverviewRepository
import com.nexus.core.model.ConnectionState
import com.nexus.core.model.NexusOverview
import com.nexus.core.model.NexusSubsystemStatus
import com.nexus.core.model.SubsystemType
import com.nexus.core.model.ThemePreference
import com.nexus.core.model.TransportType
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

/**
 * Fake de [NexusOverviewRepository] para testes unitários de ViewModels e casos de uso.
 */
class FakeNexusOverviewRepository : NexusOverviewRepository {

    private val state = MutableStateFlow(
        NexusOverview(
            appVersion = "0.1.0-test",
            protocolVersion = 1,
            connectionState = ConnectionState.DISCONNECTED,
            preferredTransport = TransportType.WIFI,
            supportedTransports = TransportType.entries,
            subsystems = listOf(
                NexusSubsystemStatus(
                    type = SubsystemType.CAMERA_HUB,
                    title = "Camera Hub",
                    subtitle = "Camera2 H.264",
                    phaseLabel = "Fase 2"
                ),
                NexusSubsystemStatus(
                    type = SubsystemType.DEVICE_HUB,
                    title = "Device Hub",
                    subtitle = "Pareamento e Sessão",
                    phaseLabel = "Fase 1"
                )
            ),
            themePreference = ThemePreference.SYSTEM
        )
    )

    override fun observeOverview(): Flow<NexusOverview> = state.asStateFlow()

    override suspend fun updateThemePreference(preference: ThemePreference) {
        state.update { it.copy(themePreference = preference) }
    }

    override suspend fun updatePreferredTransport(transportType: TransportType) {
        state.update { it.copy(preferredTransport = transportType) }
    }
}

