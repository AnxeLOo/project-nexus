package com.nexus.feature.dashboard.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.nexus.core.model.ThemePreference
import com.nexus.core.model.TransportType
import com.nexus.feature.dashboard.ui.components.NexusEnvironmentStatusCard
import com.nexus.feature.dashboard.ui.components.NexusHeader
import com.nexus.feature.dashboard.ui.components.NexusSubsystemTile
import com.nexus.feature.dashboard.ui.components.NexusThemeSelectorCard

/**
 * Rota principal do Dashboard que coleta o estado do [DashboardViewModel].
 */
@Composable
fun DashboardRoute(
    modifier: Modifier = Modifier,
    viewModel: DashboardViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()

    DashboardScreen(
        uiState = uiState,
        onThemePreferenceSelected = viewModel::onThemePreferenceSelected,
        onTransportSelected = viewModel::onTransportSelected,
        modifier = modifier
    )
}

/**
 * Tela inicial stateless do Nexus, demonstrando a aplicação do tema Material Design 3
 * (claro e escuro), identidade visual e separação arquitetural Clean Architecture + MVVM.
 */
@Composable
fun DashboardScreen(
    uiState: DashboardUiState,
    onThemePreferenceSelected: (ThemePreference) -> Unit,
    onTransportSelected: (TransportType) -> Unit,
    modifier: Modifier = Modifier
) {
    LazyColumn(
        modifier = modifier.fillMaxSize(),
        contentPadding = PaddingValues(horizontal = 20.dp, vertical = 16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            NexusHeader(
                appVersion = uiState.appVersion,
                protocolVersion = uiState.protocolVersion
            )
        }

        item {
            NexusEnvironmentStatusCard(
                connectionState = uiState.connectionState,
                preferredTransport = uiState.preferredTransport,
                supportedTransports = uiState.supportedTransports,
                onTransportSelected = onTransportSelected
            )
        }

        item {
            NexusThemeSelectorCard(
                currentPreference = uiState.themePreference,
                onPreferenceSelected = onThemePreferenceSelected
            )
        }

        item {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 4.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "SUBSISTEMAS ARQUITETURAIS",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "${uiState.subsystems.size} módulos",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.primary,
                    fontWeight = FontWeight.Medium
                )
            }
        }

        items(
            items = uiState.subsystems,
            key = { it.type.name }
        ) { subsystem ->
            NexusSubsystemTile(subsystem = subsystem)
        }

        item {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Text(
                    text = "Clean Architecture • Presentation → Domain → Data → Platform",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(8.dp))
            }
        }
    }
}

