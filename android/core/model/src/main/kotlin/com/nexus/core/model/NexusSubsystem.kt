package com.nexus.core.model

/**
 * Identificadores dos cinco subsistemas principais do Nexus.
 */
enum class SubsystemType {
    CAMERA_HUB,
    SCREEN_HUB,
    FILE_HUB,
    CLIPBOARD_HUB,
    DEVICE_HUB
}

/**
 * Estado resumido de um subsistema exibido na tela inicial do Nexus.
 */
data class NexusSubsystemStatus(
    val type: SubsystemType,
    val title: String,
    val subtitle: String,
    val phaseLabel: String,
    val isReadyInArchitecture: Boolean = true
)

