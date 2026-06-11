# Modid

A Minecraft mod that runs on Fabric and NeoForge from a single codebase. Built from feltfomo's multiloader template.

You write your code in `common/`, against vanilla Minecraft. The loader folders are thin shims that just hand off to common, so you rarely open them.

## Build

No Java on the box? Use the bootstrap wrapper. It finds a JDK 25, or downloads a private one into `.jdk/` (gitignored, nothing system-wide), then runs Gradle:

    ./mcw build          # builds every loader

Already set up — Nix, or your own JDK 25 on PATH? Skip the wrapper and call Gradle directly:

    nix develop          # puts JDK 25 + Gradle on PATH
    ./gradlew build

Build or run a single loader (swap `./gradlew` for `./mcw` if you're leaning on the bootstrap):

    ./gradlew :fabric:build
    ./gradlew :fabric:runClient
    ./gradlew :neoforge:build
    ./gradlew :neoforge:runClient

Both loaders are fully wired: common logic, the client entry, and the mixin layer all fire on Fabric and NeoForge.

Use `./gradlew` (or `./mcw`), not a system `gradle`. The wrapper is pinned to a version that runs on Java 25; an older system gradle fails with a bare version-number error. `mcw` covers Linux and macOS; on Windows install Temurin 25 yourself and use `gradlew.bat`.

## Make it yours

Everything that names the mod is in `pkl/mod.pkl` - id, name, group, version, authors. Change those, then rebuild. The build regenerates the loader manifests and mixin configs from that one file, so you never touch a `fabric.mod.json` directly. To see the generated output without a full build, run `./gradlew generatePklConfigs`; it writes to `build/generated/`.

## Languages

Java is on by default and it's all you need. Kotlin and Scala are opt-in - flip a flag in `pkl/mod.pkl`:

    kotlin: Boolean = true
    scala: Boolean = true

When a flag is on, the build applies that language's plugin to `common/` and bundles its runtime into each loader jar (Fabric `include`, NeoForge `jarJar`). Kotlin's version comes from the kotlin plugin pinned in the root `build.gradle.kts`; Scala's version is `scalaVersion` in `pkl/mod.pkl`. Off by default means no extra plugins, no bundled runtimes, nothing to compile.

To add code in a language you've enabled, drop it under the matching source root:

    common/src/main/kotlin/com/example/modid/...
    common/src/main/scala/com/example/modid/...

A Kotlin or Scala entry point is just a class your common code calls - wire it in from `ModInit`. Keep mixins in Java: Kotlin and Scala compiled output fights Mixin's bytecode model.

## Mixins

Put your mixin class under `common/src/main/java/.../mixin/` (or `.../mixin/client/` for client-only), add its name to the mixin list in `pkl/mod.pkl`, and rebuild. One entry and every loader picks it up.

## Datagen

Recipes, advancements, and tags are generated from code, not hand-written JSON. Each loader has a sample recipe provider in its `datagen/` package to copy from - delete it once you've written your own.

    ./gradlew :fabric:runDatagen
    ./gradlew :neoforge:runServerData

Output lands in the loader's `generated/` dir (`fabric/src/main/generated`, `neoforge/src/generated/resources`) and rides into that loader's jar. It's gitignored, so a plain `build` from a fresh clone ships no generated data - run the task first, and rerun it whenever you touch a provider. On Fabric the Fabric API is pulled in for datagen only: not bundled, not declared as a depend, so your shipped mod stays dependency-free.

Don't want it? Set `datagen: Boolean = false` in `pkl/mod.pkl` (or scaffold with `SCAFFOLD_DATAGEN=0`) and the providers and runs drop out.

## What's where

    pkl/mod.pkl   your mod's identity, languages, and mixin list
    common/       your code, compiled against vanilla
    fabric/       fabric entry shim
    neoforge/     neoforge entry shim

Most of your time is spent in `common/`.
