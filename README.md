# feltfomo-multiloader-template

One Minecraft mod codebase that runs on Fabric, NeoForge, and Quilt. You write the mod once, in whatever JVM language you like, against vanilla Minecraft plus Mixins. No per-loader source trees, no loader-specific API, no remapping dance.

Built for modern, unobfuscated Minecraft (26.1.x) on Java 25.

## Why this exists

Modern Minecraft ships unobfuscated, and every current loader speaks Mixin. The old multiloader pain (remapping, per-loader copies of everything) is mostly gone. This template leans all the way into that:

- **One source of truth.** Mod metadata, dependencies, and the Mixin config list live in a single Pkl file (`pkl/mod.pkl`). One `pkl eval` renders every loader manifest: `fabric.mod.json`, `quilt.mod.json`, `neoforge.mods.toml`, and the Mixin JSON files. You never hand-edit a loader manifest again.
- **Write to common, not to a loader.** All your code lives in `common/`, compiled against vanilla. Each loader gets a tiny Java shim that does nothing but hand off to common. Adding behavior feels like making a mod for a single loader.
- **Mixins are the only thing that touches the game, declared once.** Because you target vanilla, a Mixin written once applies on every loader.
- **Pick your language.** Java, Kotlin, Scala, and Groovy are all first-class in `common`. Use one, use all four. (Clojure works for logic too; see `DESIGN.md`.)

Read `DESIGN.md` for the full rationale and the trade-offs.

## Requirements

The repo ships a Nix flake with everything pinned (Java 25, Pkl, Gradle). With Nix:

```bash
nix develop
```

drops you into a shell with the right Java, Pkl, and Gradle on PATH. No Nix? Install Java 25, Pkl 0.31+, and Gradle 9.4+ yourself.

## Quick start

```bash
nix develop                                # or bring your own Java 25 / Pkl / Gradle
pkl eval -m build/generated pkl/mod.pkl    # render the loader manifests
./gradlew build                            # build every loader
```

Run the game:

```bash
./gradlew :fabric:runClient
./gradlew :neoforge:runClient
./gradlew :quilt:runClient     # quilt is optional, see below
./gradlew :fabric:runServer
```

## Editing your mod's identity

Everything that describes the mod lives in `pkl/mod.pkl`:

```pkl
amends "Mod.pkl"

id = "modid"
group = "com.example.modid"
version = "1.0.0"
name = "Modid"
authors = new { "yourname" }
license = "MIT"
// ...mc + loader versions, mixin lists
```

Change a value, run `pkl eval -m build/generated pkl/mod.pkl`, and all five manifests regenerate. The output lands in `build/generated/` (gitignored) and the build copies each file into the right loader's resources.

## Registering a mixin

Drop your Mixin class in `common/src/main/java/.../mixin/` (or `.../mixin/client/` for client-only), then add its entry to the mixin lists in `pkl/mod.pkl` and re-run `pkl eval`. That one change rewrites `modid.mixins.json` and `modid.client.mixins.json`, and every loader picks them up. You register a mixin once, not once per loader.

## Layout

```
.
├── flake.nix              # dev shell: Java 25, Pkl, Gradle
├── pkl/
│   ├── Mod.pkl            # schema: the shape of a mod
│   └── mod.pkl            # your mod's actual values
├── example-template/
│   └── modid/             # example output; "modid" is the placeholder name
│       ├── common/        # all your code + mixins, vanilla-only
│       ├── fabric/        # Java shim
│       ├── neoforge/      # Java shim
│       └── quilt/         # Java shim (optional)
└── new-mc-mod.sh          # scaffold a fresh project
```

Everything you write goes in `common`. The loader projects hold no mod logic of their own; they pull in `common` and add the loader wiring on top.

## Languages and compile order

Inside each source set Java compiles first, Kotlin next, Scala last, so Scala sees the Java and Kotlin classes. Groovy fits the same model. Write the loader shims in Java (they're a few lines each), then write everything else in whatever you reach for.

## Loaders

Fabric and NeoForge are the primary targets. Quilt is supported but optional: it's a runtime choice. If Quilt gives you trouble, skip it, the same common code still runs on Fabric and NeoForge.

## Versions

| Tool | Version |
|---|---|
| Minecraft | 26.1.2 |
| Java | 25 |
| Gradle | 9.4 |
| Fabric Loader | 0.19.3 |
| NeoForge | 26.1.2.73 |
| Quilt Loader | 0.29.0 |
| Kotlin | 2.4.0 |
| Scala | 3.8.3 |

Manifest versions live in `pkl/mod.pkl`; build coordinates live in `gradle.properties`.

## License

MIT. See `LICENSE`.
