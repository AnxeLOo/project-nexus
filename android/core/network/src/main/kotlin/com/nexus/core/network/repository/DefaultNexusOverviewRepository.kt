package com.nexus.core.network.repository

import com.nexus.core.domain.repository.NexusOverviewRepository
import com.nexus.core.model.ConnectionState
import com.nexus.core.model.NexusOverview
import com.nexus.core.model.NexusSubsystemStatus
import com.nexus.core.model.SubsystemType
import com.nexus.core.model.ThemePreference
import com.nexus.core.model.TransportType
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update

/**
 * Implementação inicial da camada Data para [NexusOverviewRepository].
 * Mantém o estado inicial em memória para validar a arquitetura Clean Architecture + MVVM
 * sem acoplar conectividade real de rede (fora do escopo da configuração inicial).
 */
@Singleton
class DefaultNexusOverviewRepository @Inject constructor() : NexusOverviewRepository {

    private val overviewState = MutableStateFlow(
        NexusOverview(
            appVersion = "0.1.0-foundation",
            protocolVersion = 1,
            connectionState = ConnectionState.DISCONNECTED,
            preferredTransport = TransportType.WIFI,
            supportedTransports = TransportType.entries,
            subsystems = listOf(
                NexusSubsystemStatus(
                    type = SubsystemType.CAMERA_HUB,
                    title = "Camera Hub",
                    subtitle = "Camera2 H.264 & Controles Manuais",
                    phaseLabel = "Fase 2"
                ),
                NexusSubsystemStatus(
                    type = SubsystemType.SCREEN_HUB,
                    title = "Screen Hub",
                    subtitle = "MediaProjection & Controle Remoto",
                    phaseLabel = "Fase 2"
                ),
                NexusSubsystemStatus(
                    type = SubsystemType.FILE_HUB,
                    title = "File Hub",
                    subtitle = "Transferência TCP/TLS & SHA-256",
                    phaseLabel = "Fase 1"
                ),
                NexusSubsystemStatus(
                    type = SubsystemType.CLIPBOARD_HUB,
                    title = "Clipboard Hub",
                    subtitle = "Área de Transferência Sincronizada",
                    phaseLabel = "Fase 1"
                ),
                NexusSubsystemStatus(
                    type = SubsystemType.DEVICE_HUB,
                    title = "Device Hub",
                    subtitle = "mDNS, Pareamento & Sessão Segura",
                    phaseLabel = "Fase 1"
                )
            ),
            themePreference = ThemePreference.SYSTEM
        )
    )

    override fun observeOverview(): Flow<NexusOverview> = overviewState.asStateFlow()

    override suspend fun updateThemePreference(preference: ThemePreference) {
        overviewState.update { current ->
            current.copy(themePreference = preference)
        }
    }

    override suspend fun updatePreferredTransport(transportType: TransportType) {
        overviewState.update { current ->
            current.copy(preferredTransport = transportType)
        }
    }
}

