package com.nexus.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.nexus.app.navigation.NexusAppShell
import com.nexus.app.ui.theme.NexusTheme
import dagger.hilt.android.AndroidEntryPoint

/**
 * Activity principal do aplicativo Nexus Android.
 * Configura renderização edge-to-edge e aplica o [NexusTheme] (Material Design 3)
 * respeitando a preferência do sistema ou a seleção de tema ativa.
 */
@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    private val mainViewModel: MainViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            val themePreference by mainViewModel.themePreference.collectAsStateWithLifecycle()

            NexusTheme(themePreference = themePreference) {
                NexusAppShell()
            }
        }
    }
}

