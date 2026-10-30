package com.nexus.core.network.di

import com.nexus.core.domain.repository.NexusOverviewRepository
import com.nexus.core.network.repository.DefaultNexusOverviewRepository
import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class NetworkDataModule {

    @Binds
    @Singleton
    abstract fun bindNexusOverviewRepository(
        impl: DefaultNexusOverviewRepository
    ): NexusOverviewRepository
}

