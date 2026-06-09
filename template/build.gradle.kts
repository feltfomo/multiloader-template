// Root build script. Shared config + the Pkl generation step.
// All real code lives in common/ and the loader modules.

subprojects {
    group = providers.gradleProperty("mod_group").get()
    version = providers.gradleProperty("mod_version").get()
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
