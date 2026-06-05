# feltfomo-multiloader-template

A generator for Minecraft 26.1.2 mods targeting Fabric and NeoForge from a single codebase. Run `new-mc-mod.sh`, answer the prompts, and get a zip with a complete Gradle project, loader manifests, mixin configs, and Scala entrypoints filled in for your mod.

The `modid/` directory in this repo is the example output — the script uses `modid` as the placeholder name. The README generated inside it is a stub.

## Using the script

```bash
bash new-mc-mod.sh
```

The script asks for mod id, display name, Maven group, version, authors, license, and description. It derives the package directory path from the group and the class name prefix by PascalCasing the display name. After printing a summary it writes the project, zips it to `<modid>-template.zip`, and removes the working directory.

## Project structure

The generated project is a Gradle multi-project build with three subprojects.

```
<modid>/
├── common/             # All mod logic, compiled against vanilla only
│   └── src/
│       ├── main/       # Server-safe code
│       └── client/     # Client-only code
├── fabric/             # Fabric loader shim
├── neoforge/           # NeoForge loader shim
├── gradle.properties
└── settings.gradle.kts
```

All mod code lives in `common`. The `fabric` and `neoforge` subprojects contain no mod logic — they depend on `common` via `compileOnly(commonProject)` and add only loader-specific wiring. Each module has parallel source roots under both `main` and `client` environments: `java/`, `kotlin/`, `scala/`, and `resources/`.

Default versions: Minecraft 26.1.2, Java 25, Kotlin 2.4.0, Scala 3.8.3, Fabric Loader 0.19.3, NeoForge 26.1.2.73. These are all in `gradle.properties`.

## Running

Java 25 is required. Gradle 9.4 is bundled via the wrapper.

```bash
./gradlew :fabric:runClient
./gradlew :fabric:runServer
./gradlew :neoforge:runClient
./gradlew :neoforge:runServer     # starts with --nogui
```

## Languages

Within each module, Java compiles first, Kotlin second, Scala last. `common/build.gradle.kts` makes this explicit:

```kotlin
tasks.named("compileScala")       { dependsOn("compileKotlin", "compileJava") }
tasks.named("compileClientScala") { dependsOn("compileClientKotlin", "compileClientJava") }
```

Scala sees the complete compiled output of both. Java and Kotlin see neither.

Both loaders use [Kotori316's SLP](https://github.com/Kotori316/SLP) to register Scala objects as entrypoints. On Fabric, `fabric.mod.json` declares the `kotori_scala` adapter pointing to `ModidFabric` and `ModidClientFabric`. On NeoForge, `neoforge.mods.toml` sets `modLoader = "kotori_scala"` and `modEntry = "...ModidNeoForge"`. The `@Mod` annotation on that object is a NeoForge Java annotation; the `MOD_ID` argument is a Scala 3 `inline val`, which the compiler inlines to the string literal at the use site so the annotation processor sees a constant.

`ModidFabric.onInitialize` and `ModidNeoForge.apply` both delegate immediately to `ModidCommon.init()`. From there the mod runs inside `common`. Any Kotlin-defined registries or event handlers are already compiled and on the classpath by that point; Scala can call into them directly. The mixin source roots — `java/` under `main` and `client` in all three modules — are where vanilla's mixin framework expects to find annotated classes.
