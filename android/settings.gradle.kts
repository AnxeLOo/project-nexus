pluginManagement {
    repositories {
        google {
            content {
                includeGroupByRegex("com\\.android.*")
                includeGroupByRegex("com\\.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "NexusAndroid"

enableFeaturePreview("TYPESAFE_PROJECT_ACCESSORS")

include(":app")

// Core Modules (Domain, Models & Data Infrastructure)
include(":core:common")
include(":core:model")
include(":core:domain")
include(":core:database")
include(":core:network")
include(":core:protocol")
include(":core:security")
include(":core:testing")

// Feature Modules (Presentation / MVVM)
include(":feature:dashboard")
include(":feature:pairing")
include(":feature:screenstream")
include(":feature:remotecontrol")
include(":feature:camera")
include(":feature:filetransfer")
include(":feature:clipboard")
include(":feature:devices")
include(":feature:settings")

// Platform Infrastructure Modules (Low-level Android APIs)
include(":platform:camera2")
include(":platform:mediaprojection")
include(":platform:webrtc")
include(":platform:transport")
include(":platform:accessibility")

