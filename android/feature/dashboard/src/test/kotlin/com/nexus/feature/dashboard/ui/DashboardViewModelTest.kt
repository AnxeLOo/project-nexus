package com.nexus.feature.dashboard.ui

import com.nexus.core.domain.usecase.ObserveNexusOverviewUseCase
import com.nexus.core.domain.usecase.SelectPreferredTransportUseCase
import com.nexus.core.domain.usecase.UpdateThemePreferenceUseCase
import com.nexus.core.model.ConnectionState
import com.nexus.core.model.ThemePreference
import com.nexus.core.model.TransportType
import com.nexus.core.testing.repository.FakeNexusOverviewRepository
import com.nexus.core.testing.util.MainDispatcherRule
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Before
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class DashboardViewModelTest {

    @get:Rule
    val mainDispatcherRule = MainDispatcherRule()

    private lateinit var repository: FakeNexusOverviewRepository
    private lateinit var viewModel: DashboardViewModel

    @Before
    fun setup() {
        repository = FakeNexusOverviewRepository()
        viewModel = DashboardViewModel(
            observeNexusOverviewUseCase = ObserveNexusOverviewUseCase(repository),
            updateThemePreferenceUseCase = UpdateThemePreferenceUseCase(repository),
            selectPreferredTransportUseCase = SelectPreferredTransportUseCase(repository)
        )
    }

    @Test
    fun `when collecting uiState then emits initial overview from domain`() = runTest {
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) {
            viewModel.uiState.collect()
        }

        val state = viewModel.uiState.value
        assertFalse(state.isLoading)
        assertEquals(ConnectionState.DISCONNECTED, state.connectionState)
        assertEquals(ThemePreference.SYSTEM, state.themePreference)
        assertEquals(TransportType.WIFI, state.preferredTransport)
        assertEquals(2, state.subsystems.size)
    }

    @Test
    fun `when theme or transport is updated then uiState reflects changes reactively`() = runTest {
        backgroundScope.launch(UnconfinedTestDispatcher(testScheduler)) {
            viewModel.uiState.collect()
        }

        viewModel.onThemePreferenceSelected(ThemePreference.DARK)
        viewModel.onTransportSelected(TransportType.USB)

        val state = viewModel.uiState.value
        assertEquals(ThemePreference.DARK, state.themePreference)
        assertEquals(TransportType.USB, state.preferredTransport)
    }
}

