package com.nexus.core.domain.usecase

import com.nexus.core.domain.repository.NexusOverviewRepository
import com.nexus.core.model.TransportType
import javax.inject.Inject

/**
 * Caso de uso para alterar o modo de transporte preferencial (USB, Wi-Fi ou Wi-Fi Direct).
 */
class SelectPreferredTransportUseCase @Inject constructor(
    private val repository: NexusOverviewRepository
) {
    suspend operator fun invoke(transportType: TransportType) {
        repository.updatePreferredTransport(transportType)
    }
}

