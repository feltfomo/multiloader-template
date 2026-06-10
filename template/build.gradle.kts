import mod.ModConfig

// Root build script. Shared config + the Pkl generation step.
// All real code lives in common/ and the loader modules.

// Declare every build-script plugin here with `apply false` so they all load
// from ONE classloader shared by the subprojects. Fabric Loom is fragile about
// this: if Loom and the Kotlin plugin resolve in separate plugin scopes (e.g.
// both declared in settings pluginManagement), Loom's extension class loads
// twice and you hit "LoomGradleExtensionImpl_Decorated cannot be cast to
// LoomGradleExtension". Subprojects apply these version-less.
plugins {
    id("net.fabricmc.fabric-loom") version "1.17.3" apply false
    id("net.neoforged.moddev") version "2.0.141" apply false
    id("org.jetbrains.kotlin.jvm") version "2.4.0" apply false
}

// Read identity once from pkl/mod.pkl (see buildSrc) and hand it to every
// subproject. gradle.properties no longer owns these.
val modConfig = ModConfig.load(rootDir.resolve("pkl/mod.pkl"))

subprojects {
    group = modConfig.group
    version = modConfig.version
}

// Single source of truth: pkl/mod.pkl renders every loader manifest + mixin
// config into build/generated. Loader modules copy what they need from there.
// Needs `pkl` on PATH \u2014 the flake devshell provides it.
val generatePklConfigs by tasks.registering(Exec::class) {
    workingDir = rootDir
    commandLine("pkl", "eval", "-m", "build/generated", "pkl/mod.pkl")
    inputs.file("pkl/Mod.pkl")
    inputs.file("pkl/mod.pkl")
    outputs.dir(layout.buildDirectory.dir("generated"))
}
