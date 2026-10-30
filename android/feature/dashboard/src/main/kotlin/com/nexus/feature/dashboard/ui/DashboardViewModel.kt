package com.nexus.feature.dashboard.ui

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.nexus.core.domain.usecase.ObserveNexusOverviewUseCase
import com.nexus.core.domain.usecase.SelectPreferredTransportUseCase
import com.nexus.core.domain.usecase.UpdateThemePreferenceUseCase
import com.nexus.core.model.ThemePreference
import com.nexus.core.model.TransportType
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

/**
 * ViewModel da tela inicial (Dashboard) seguindo o padrão MVVM com fluxo unidirecional (StateFlow).
 * Consome exclusivamente casos de uso da camada Domain.
 */
@HiltViewModel
class DashboardViewModel @Inject constructor(
    observeNexusOverviewUseCase: ObserveNexusOverviewUseCase,
    private val updateThemePreferenceUseCase: UpdateThemePreferenceUseCase,
    private val selectPreferredTransportUseCase: SelectPreferredTransportUseCase
) : ViewModel() {

    val uiState: StateFlow<DashboardUiState> = observeNexusOverviewUseCase()
        .map { overview ->
            DashboardUiState(
                isLoading = false,
                appVersion = overview.appVersion,
                protocolVersion = overview.protocolVersion,
                connectionState = overview.connectionState,
                preferredTransport = overview.preferredTransport,
                supportedTransports = overview.supportedTransports,
                subsystems = overview.subsystems,
                themePreference = overview.themePreference
            )
        }
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = DashboardUiState()
        )

    fun onThemePreferenceSelected(preference: ThemePreference) {
        viewModelScope.launch {
            updateThemePreferenceUseCase(preference)
        }
    }

    fun onTransportSelected(transportType: TransportType) {
        viewModelScope.launch {
            selectPreferredTransportUseCase(transportType)
        }
    }
}

