package com.nexus.core.common.result

/**
 * Representação explícita de resultado de operações assíncronas entre camadas.
 */
sealed interface NexusResult<out T> {
    data class Success<T>(val data: T) : NexusResult<T>
    data class Error(val exception: Throwable, val message: String? = exception.message) : NexusResult<Nothing>
    data object Loading : NexusResult<Nothing>
}

