package com.nexus.core.domain.repository

import com.nexus.core.model.NexusOverview
import com.nexus.core.model.ThemePreference
import com.nexus.core.model.TransportType
import kotlinx.coroutines.flow.Flow

/**
 * Contrato de domínio para observar e atualizar as preferências iniciais do ambiente Nexus.
 * Implementado na camada Data sem expor detalhes de infraestrutura para o domínio.
 */
interface NexusOverviewRepository {
    fun observeOverview(): Flow<NexusOverview>
    suspend fun updateThemePreference(preference: ThemePreference)
    suspend fun updatePreferredTransport(transportType: TransportType)
}

