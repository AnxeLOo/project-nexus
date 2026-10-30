package com.nexus.core.domain.usecase

import com.nexus.core.domain.repository.NexusOverviewRepository
import com.nexus.core.model.NexusOverview
import javax.inject.Inject
import kotlinx.coroutines.flow.Flow

/**
 * Caso de uso responsável por expor o fluxo reativo com a visão geral do sistema Nexus.
 */
class ObserveNexusOverviewUseCase @Inject constructor(
    private val repository: NexusOverviewRepository
) {
    operator fun invoke(): Flow<NexusOverview> = repository.observeOverview()
}

