import mod.ModConfig

// Root build script. Shared config + the Pkl generation step.
// All real code lives in common/ and the loader modules.

// Declare the loader + Kotlin plugins here with `apply false` so they all load
// from ONE classloader shared by the subprojects. Fabric Loom is fragile about
// this: if Loom and the Kotlin plugin resolve in separate plugin scopes (e.g.
// both declared in settings pluginManagement), Loom's extension class loads
// twice and you hit "LoomGradleExtensionImpl_Decorated cannot be cast to
// LoomGradleExtension". Subprojects apply these version-less.
plugins {
    id("net.fabricmc.fabric-loom") version "1.17.3" apply false
    id("net.neoforged.moddev") version "2.0.141" apply false
    id("org.jetbrains.kotlin.jvm") version "2.4.0" apply false
    id("org.pkl-lang") version "0.31.1"
}

// Read identity once from pkl/mod.pkl (see buildSrc) and hand it to every
// subproject. gradle.properties no longer owns these.
val modConfig = ModConfig.load(rootDir.resolve("pkl/mod.pkl"))

subprojects {
    group = modConfig.group
    version = modConfig.version
}

// Access widener (Fabric) + access transformer (NeoForge) are rendered from one
// pkl list. Write them at configure time into a stable dir outside build/ so the
// loader plugins can read them on a clean build -- their inputs are wired during
// configuration, before `clean` deletes build/. Loader modules read this dir.
val accessGenDir = rootDir.resolve(".pkl-generated")
if (modConfig.hasAccessWideners) modConfig.writeAccessFiles(accessGenDir)

// Single source of truth: pkl/mod.pkl renders every loader manifest + mixin
// config into build/generated. Loader modules copy what they need from there.
// The pkl-gradle plugin evaluates pkl/mod.pkl with an embedded evaluator; no pkl binary needed.
pkl {
    evaluators {
        register("generatePklConfigs") {
            sourceModules.add(file("pkl/mod.pkl"))
            multipleFileOutputDir.set(layout.buildDirectory.dir("generated"))
        }
    }
}
