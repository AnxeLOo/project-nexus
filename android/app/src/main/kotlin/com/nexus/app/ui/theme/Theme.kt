package com.nexus.app.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat
import com.nexus.core.model.ThemePreference

private val DarkColorScheme = darkColorScheme(
    primary = NexusDarkPrimary,
    onPrimary = NexusDarkOnPrimary,
    primaryContainer = NexusDarkPrimaryContainer,
    onPrimaryContainer = NexusDarkOnPrimaryContainer,
    secondary = NexusDarkSecondary,
    onSecondary = NexusDarkOnSecondary,
    secondaryContainer = NexusDarkSecondaryContainer,
    onSecondaryContainer = NexusDarkOnSecondaryContainer,
    tertiary = NexusDarkTertiary,
    onTertiary = NexusDarkOnTertiary,
    tertiaryContainer = NexusDarkTertiaryContainer,
    onTertiaryContainer = NexusDarkOnTertiaryContainer,
    background = NexusDarkBackground,
    onBackground = NexusDarkOnBackground,
    surface = NexusDarkSurface,
    onSurface = NexusDarkOnSurface,
    surfaceVariant = NexusDarkSurfaceVariant,
    onSurfaceVariant = NexusDarkOnSurfaceVariant,
    error = NexusDarkError,
    onError = NexusDarkOnError,
    errorContainer = NexusDarkErrorContainer,
    onErrorContainer = NexusDarkOnErrorContainer,
    outline = NexusDarkOutline,
    outlineVariant = NexusDarkOutlineVariant
)

private val LightColorScheme = lightColorScheme(
    primary = NexusLightPrimary,
    onPrimary = NexusLightOnPrimary,
    primaryContainer = NexusLightPrimaryContainer,
    onPrimaryContainer = NexusLightOnPrimaryContainer,
    secondary = NexusLightSecondary,
    onSecondary = NexusLightOnSecondary,
    secondaryContainer = NexusLightSecondaryContainer,
    onSecondaryContainer = NexusLightOnSecondaryContainer,
    tertiary = NexusLightTertiary,
    onTertiary = NexusLightOnTertiary,
    tertiaryContainer = NexusLightTertiaryContainer,
    onTertiaryContainer = NexusLightOnTertiaryContainer,
    background = NexusLightBackground,
    onBackground = NexusLightOnBackground,
    surface = NexusLightSurface,
    onSurface = NexusLightOnSurface,
    surfaceVariant = NexusLightSurfaceVariant,
    onSurfaceVariant = NexusLightOnSurfaceVariant,
    error = NexusLightError,
    onError = NexusLightOnError,
    errorContainer = NexusLightErrorContainer,
    onErrorContainer = NexusLightOnErrorContainer,
    outline = NexusLightOutline,
    outlineVariant = NexusLightOutlineVariant
)

/**
 * Tema Material Design 3 do Nexus Android.
 * Respeita por padrão a preferência do sistema ([ThemePreference.SYSTEM]), suportando
 * também seleção explícita entre tema Claro e Escuro.
 */
@Composable
fun NexusTheme(
    themePreference: ThemePreference = ThemePreference.SYSTEM,
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit
) {
    val systemDarkTheme = isSystemInDarkTheme()
    val useDarkTheme = when (themePreference) {
        ThemePreference.SYSTEM -> systemDarkTheme
        ThemePreference.LIGHT -> false
        ThemePreference.DARK -> true
    }

    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (useDarkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        useDarkTheme -> DarkColorScheme
        else -> LightColorScheme
    }

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as? Activity)?.window ?: return@SideEffect
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !useDarkTheme
            WindowCompat.getInsetsController(window, view).isAppearanceLightNavigationBars = !useDarkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = NexusTypography,
        shapes = NexusShapes,
        content = content
    )
}

