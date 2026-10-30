package com.nexus.app

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.nexus.core.domain.usecase.ObserveNexusOverviewUseCase
import com.nexus.core.model.ThemePreference
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn

/**
 * ViewModel de nível de Activity para observar a preferência global de tema Material 3.
 */
@HiltViewModel
class MainViewModel @Inject constructor(
    observeNexusOverviewUseCase: ObserveNexusOverviewUseCase
) : ViewModel() {

    val themePreference: StateFlow<ThemePreference> = observeNexusOverviewUseCase()
        .map { it.themePreference }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = ThemePreference.SYSTEM
        )
}

