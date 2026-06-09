pluginManagement {
    repositories {
        maven {
            name = "Fabric"
            url = uri("https://maven.fabricmc.net/")
        }
        maven {
            name = "NeoForge"
            url = uri("https://maven.neoforged.net/releases")
        }
        mavenCentral()
        gradlePluginPortal()
    }

    plugins {
        id("net.fabricmc.fabric-loom") version "1.16-SNAPSHOT"
    }
}

plugins {
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

rootProject.name = "modid"

include("common")
include("fabric")
// neoforge is wired back in during Stage B
