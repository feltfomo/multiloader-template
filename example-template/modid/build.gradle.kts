// Root build script. Shared config only.
// All real code lives in common/, fabric/, neoforge/.

plugins {
    id("org.jetbrains.kotlin.jvm")
}

subprojects {
    group = providers.gradleProperty("mod_group").get()
    version = providers.gradleProperty("mod_version").get()
}
