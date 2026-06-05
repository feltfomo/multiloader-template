# feltfomo-multiloader-template

A generator for Minecraft 26.1.2 mods that run on both Fabric and NeoForge from one codebase. Run `new-mc-mod.sh`, answer a handful of prompts, and you get a zip with a full Gradle project: loader manifests, mixin configs, and Scala entrypoints already filled in.

The `modid/` folder in this repo is example output. The script uses `modid` as the placeholder name, so that's what you'll see all through it. The README inside that folder is just a stub.

## Using the script

```bash
bash new-mc-mod.sh
```

It asks for the mod id, display name, Maven group, version, authors, license, and description. The package path comes from the group, and the class prefix comes from PascalCasing the display name (so "My Mod" turns into `MyMod`). After a summary it writes the project, zips it to `<modid>-template.zip`, and clears out the working directory.

## Project layout

It's a Gradle multi-project build with three subprojects.

```
<modid>/
├── common/      # all the mod logic, built against vanilla only
│   └── src/
│       ├── main/    # server-safe code
│       └── client/  # client-only code
├── fabric/      # Fabric loader shim
├── neoforge/    # NeoForge loader shim
├── gradle.properties
└── settings.gradle.kts
```

Everything you write goes in `common`. The `fabric` and `neoforge` projects hold no mod logic of their own; they pull in `common` and add the loader-specific wiring on top.

`common` and `fabric` both carry `main` and `client` source sets, each with `java/`, `kotlin/`, `scala/`, and `resources/`. `neoforge` only has `main`. Its client mixin config still ships, it just sits in `main/resources` next to the common one.

Default versions: Minecraft 26.1.2, Java 25, Kotlin 2.4.0, Scala 3.8.3, Fabric Loader 0.19.3, NeoForge 26.1.2.73. They all live in `gradle.properties`, so you bump them in one place.

## Building and running

You need Java 25. The script writes `gradle-wrapper.properties` but not the `gradlew` scripts or the wrapper jar, since those are binaries it can't generate. So run `gradle wrapper` once in the project first, or use a Gradle 9.4 install you already have.

```bash
gradle wrapper            # first time only
./gradlew :fabric:runClient
./gradlew :fabric:runServer
./gradlew :neoforge:runClient
./gradlew :neoforge:runServer    # starts with --nogui
```

## How the languages fit together

Inside each source set Java compiles first, Kotlin next, Scala last. `common/build.gradle.kts` spells it out:

```kotlin
tasks.named("compileScala")       { dependsOn("compileKotlin", "compileJava") }
tasks.named("compileClientScala") { dependsOn("compileClientKotlin", "compileClientJava") }
```

So Scala sees everything Java and Kotlin built. The other two don't see Scala. The plan is to keep Kotlin as the main language, drop into Scala for the data-heavy work and draw calls, and reach for Java only when a binding is awkward anywhere else.

## How the loaders find the mod

Both loaders use [Kotori316's SLP](https://github.com/Kotori316/SLP) so the entrypoints can be Scala. On Fabric, `fabric.mod.json` sets the `kotori_scala` adapter and points at `ModidFabric` and `ModidClientFabric`. On NeoForge, `neoforge.mods.toml` sets `modLoader = "kotori_scala"` and `modEntry = "...ModidNeoForge"`.

`@Mod` is a NeoForge Java annotation and it wants a constant. `MOD_ID` is a Scala 3 `inline val`, so the compiler drops in the string literal before the annotation processor ever looks at it.

The entrypoints stay tiny:

- `ModidFabric.onInitialize` calls `ModidCommon.init()`, and `ModidClientFabric.onInitializeClient` calls `ModidClientCommon.init()`.
- `ModidNeoForge` is a class that takes `(modBus: IEventBus, dist: Dist)`. Its constructor calls `ModidCommon.init()`, then `ModidClientCommon.init()` when `dist` is `Dist.CLIENT`. One entry handles both sides.

From there you're running inside `common`. Anything Kotlin registered is already compiled and on the classpath, so Scala calls straight into it. Mixins go in the `java/` roots where the loader's mixin framework looks for them.
