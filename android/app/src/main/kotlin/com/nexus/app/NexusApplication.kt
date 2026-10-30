package com.nexus.app

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

/**
 * Ponto de entrada da aplicação Android e raiz do grafo de dependências do Hilt.
 */
@HiltAndroidApp
class NexusApplication : Application()

