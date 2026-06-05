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
        maven {
            name = "Kotori316"
            url = uri("https://maven.kotori316.com")
        }
        maven {
            name = "MinecraftForge"
            url = uri("https://maven.minecraftforge.net/")
        }
        mavenCentral()
        gradlePluginPortal()
    }

    plugins {
        id("org.jetbrains.kotlin.jvm") version "2.4.0"
        id("net.fabricmc.fabric-loom") version "1.16-SNAPSHOT"
        id("net.neoforged.moddev") version "2.0.141"
    }
}

plugins {
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

rootProject.name = "modid"

include("common")
include("fabric")
include("neoforge")
