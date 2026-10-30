package com.nexus.core.domain.usecase

import com.nexus.core.domain.repository.NexusOverviewRepository
import com.nexus.core.model.ConnectionState
import com.nexus.core.model.NexusOverview
import com.nexus.core.model.NexusSubsystemStatus
import com.nexus.core.model.SubsystemType
import com.nexus.core.model.ThemePreference
import com.nexus.core.model.TransportType
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Test

class ObserveNexusOverviewUseCaseTest {

    @Test
    fun `when invoke is called then emits initial overview and reflects theme updates`() = runTest {
        val fakeRepo = InMemoryTestOverviewRepository()
        val observeUseCase = ObserveNexusOverviewUseCase(fakeRepo)
        val updateThemeUseCase = UpdateThemePreferenceUseCase(fakeRepo)

        val initial = observeUseCase().first()
        assertEquals(ConnectionState.DISCONNECTED, initial.connectionState)
        assertEquals(ThemePreference.SYSTEM, initial.themePreference)

        updateThemeUseCase(ThemePreference.DARK)

        val updated = observeUseCase().first()
        assertEquals(ThemePreference.DARK, updated.themePreference)
    }

    private class InMemoryTestOverviewRepository : NexusOverviewRepository {
        private val state = MutableStateFlow(
            NexusOverview(
                appVersion = "0.1.0-alpha",
                protocolVersion = 1,
                connectionState = ConnectionState.DISCONNECTED,
                preferredTransport = TransportType.WIFI,
                supportedTransports = TransportType.entries,
                subsystems = listOf(
                    NexusSubsystemStatus(
                        type = SubsystemType.DEVICE_HUB,
                        title = "Device Hub",
                        subtitle = "Pareamento e sessão",
                        phaseLabel = "Fase 1"
                    )
                ),
                themePreference = ThemePreference.SYSTEM
            )
        )

        override fun observeOverview(): Flow<NexusOverview> = state

        override suspend fun updateThemePreference(preference: ThemePreference) {
            state.value = state.value.copy(themePreference = preference)
        }

        override suspend fun updatePreferredTransport(transportType: TransportType) {
            state.value = state.value.copy(preferredTransport = transportType)
        }
    }
}

