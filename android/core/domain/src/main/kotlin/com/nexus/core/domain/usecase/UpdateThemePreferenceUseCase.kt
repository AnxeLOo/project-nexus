package com.nexus.core.domain.usecase

import com.nexus.core.domain.repository.NexusOverviewRepository
import com.nexus.core.model.ThemePreference
import javax.inject.Inject

/**
 * Caso de uso para alterar a preferência de tema (Sistema, Claro ou Escuro).
 */
class UpdateThemePreferenceUseCase @Inject constructor(
    private val repository: NexusOverviewRepository
) {
    suspend operator fun invoke(preference: ThemePreference) {
        repository.updateThemePreference(preference)
    }
}

