package com.nexus.core.common.coroutines

import javax.inject.Qualifier
import kotlin.annotation.AnnotationRetention.RUNTIME

@Qualifier
@Retention(RUNTIME)
annotation class Dispatcher(val nexusDispatcher: NexusDispatchers)

enum class NexusDispatchers {
    Default,
    IO,
    Main
}

@Qualifier
@Retention(RUNTIME)
annotation class ApplicationScope

@Qualifier
@Retention(RUNTIME)
annotation class ConnectionScope

@Qualifier
@Retention(RUNTIME)
annotation class StreamingScope

@Qualifier
@Retention(RUNTIME)
annotation class TransferScope

