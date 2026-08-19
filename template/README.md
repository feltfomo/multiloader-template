# Modid

A Fabric and NeoForge Minecraft mod generated from one shared codebase.

The scaffolder already selected the project language and physical side, removed unused starters, and wired the matching manifests and loader entrypoints. Most work belongs in `common/`.

## Build

With no system JDK setup:

```bash
./mcw build
```

`mcw` finds JDK 25 or downloads a private Temurin 25 into `.jdk/`, then runs the pinned Gradle wrapper.

With Nix or an existing JDK 25:

```bash
nix develop
./gradlew build
```

Build or run one loader:

```bash
./gradlew :fabric:build
./gradlew :neoforge:build
./gradlew :fabric:runClient
./gradlew :neoforge:runClient
```

Use the `runServer` tasks instead for a dedicated-server archetype. Replace `./gradlew` with `./mcw` when relying on the bootstrap wrapper.

## Nix development environment

The generated flake uses flake-parts and provides JDK 25 plus the Linux libraries needed by LWJGL for OpenGL, Vulkan, X11, Wayland, and audio. GPU drivers remain the host operating system's responsibility.

```bash
nix develop
nix fmt
nix flake check
```

Add project-specific packages in `dev.nix`. Formatting is configured in `formatter.nix` through treefmt; generated and disposable directories are excluded. Continue using the Gradle wrapper rather than adding a system Gradle package.

## Start writing code

The chosen starter is named `ModInit` for shared or server-safe initialization and `ClientInit` for physical-client initialization.

The scaffolder keeps only what the selected side needs:

- `both` keeps `ModInit` and `ClientInit`
- `client` keeps `ClientInit`
- `server` keeps `ModInit`

The starter uses the selected language under the matching source root:

```text
common/src/main/java/...
common/src/main/kotlin/...
common/src/main/scala/...
```

Java client code uses the split `common/src/client/java/` source set. Kotlin and Scala client starters use a client package in the selected main-language root. The loader shims remain Java and should rarely need edits.

## Project configuration

Edit `pkl/mod.pkl`. It is the public project file and contains:

- id, name, group, version, authors, license, and description
- `side` as `both`, `client`, or `server`
- `language` as `java`, `kotlin`, or `scala`
- datagen, loader versions, mixins, and access entries

`pkl/render.pkl` contains the schema and loader-format machinery. Leave it alone unless changing how the template itself renders manifests.

Generate the loader files without a full build:

```bash
./gradlew generatePklConfigs
```

The task writes `fabric.mod.json`, `neoforge.mods.toml`, and the applicable mixin configs under `build/generated/`.

## Languages

The generated project applies and bundles only the selected language runtime:

- Java adds no extra runtime
- Kotlin applies the Kotlin plugin and bundles `kotlin-stdlib`
- Scala applies the Scala plugin and bundles the Scala 3 library

Fabric uses jar-in-jar and NeoForge uses `jarJar`. Mixins remain Java even in Kotlin and Scala projects because Mixin injection methods depend on predictable bytecode.

## Physical sides

The side choice changes real source and metadata, not just a label:

- client removes shared entrypoints and server-data examples
- server removes client entrypoints, client sources, and client mixins
- both keeps shared and client paths

Fabric receives the matching `environment` and entrypoint set. NeoForge uses separate common and `Dist.CLIENT` annotations, with unused classes removed by the scaffolder.

## Mixins

Put shared mixins under:

```text
common/src/main/java/.../mixin/
```

Put client mixins under:

```text
common/src/client/java/.../mixin/client/
```

Add class names to `commonMixins` or `clientMixins` in `pkl/mod.pkl`. Pkl propagates each applicable config to both loaders.

## Datagen

The bundled datagen example emits server recipe data. Both-side and server projects enable it by default; client projects default it off.

Run the providers with:

```bash
./gradlew :fabric:runDatagen
./gradlew :neoforge:runServerData
```

Outputs land in each loader's generated-resource directory and are gitignored. Set `datagen = false` in `pkl/mod.pkl` to disable the build wiring in an existing project.

## Layout

```text
pkl/mod.pkl       public project configuration
pkl/render.pkl    schema and manifest renderers
dev.nix           customizable development shell
formatter.nix     treefmt configuration
common/           selected starter and mixins
fabric/           Fabric loader shim
neoforge/         NeoForge loader shim
```

Start in `common/`, keep loader-specific code thin, and let Pkl keep both loader manifests aligned.
