# feltfomo-multiloader-template

One mod, written once, that runs on Fabric and NeoForge (and Quilt if you want it). You write against vanilla Minecraft plus Mixins. No loader-specific API, no per-loader copies of your code, no remapping.

This only works because modern Minecraft (26.1+) ships unobfuscated and every loader speaks Mixin. The old multiloader tax is mostly gone. This template just leans on that hard.

## The idea

Your code lives in `common/`, compiled against vanilla. Each loader gets a tiny Java shim that does nothing but call into common. Adding a feature feels like writing a single-loader mod, because most of the time it is.

The stuff you'd normally hand-maintain per loader is generated instead. The loader manifests (`fabric.mod.json`, `quilt.mod.json`, `neoforge.mods.toml`) and the Mixin config JSON all come out of one Pkl file, `template/pkl/mod.pkl`. Change a value there, rebuild, and every manifest regenerates. So you set your version once and register a mixin once, not once per loader.

`DESIGN.md` has the reasoning and the trade-offs. Read it if you want the why.

## Status

Where this actually is right now:

- Fabric builds and runs.
- NeoForge skeleton is in the tree but not wired into the build yet. It's next.
- Quilt is planned and optional.
- Java only for the moment. The Kotlin/Scala/Groovy source sets come back once the loaders are sorted out.

## Layout

Repo root is template-repo stuff. The buildable project (the part you copy when you scaffold) lives under `template/`:

```
.
├── README.md          this file
├── DESIGN.md          why it's built this way
├── new-mc-mod.sh      scaffold script (getting replaced by a flake template)
└── template/          the project you build and copy
    ├── flake.nix      dev shell: Java 25, Pkl, Gradle
    ├── pkl/
    │   ├── Mod.pkl    the schema
    │   └── mod.pkl    your mod's values
    ├── common/        all your code + mixins, vanilla-only
    ├── fabric/        java shim
    └── neoforge/      java shim (not in the build yet)
```

## Building it

Everything runs from `template/`, not the repo root — that's where the flake and Gradle wrapper live.

```bash
cd template
nix develop                  # Java 25 + Pkl + Gradle on PATH
./gradlew :fabric:build
```

No Nix? Bring your own Java 25, Pkl 0.31+, and Gradle 9.4+. Use `./gradlew`, not a system `gradle` — the wrapper pins 9.4.1, which is what Loom expects.

`./gradlew build` runs the Pkl step (`generatePklConfigs`) before it compiles, so the manifests are always current. You don't have to run `pkl eval` by hand unless you want to eyeball the output.

## Changing your mod's identity

It's all in `template/pkl/mod.pkl`:

```pkl
amends "Mod.pkl"

id = "modid"
group = "com.example.modid"
name = "Modid"
version = "1.0.0"
authors = new { "yourname" }
license = "MIT"
```

Edit, rebuild, done. Those values fan out into every manifest.

## Versions

| | |
|---|---|
| Minecraft | 26.1.2 |
| Java | 25 |
| Gradle | 9.4.1 (wrapper) |
| Fabric Loader | 0.19.3 |
| NeoForge | 26.1.2.73 |
| Quilt Loader | 0.29.0 |

Manifest versions live in `template/pkl/mod.pkl`; Gradle coordinates live in `template/gradle.properties`. Yes, that's the same numbers in two places. Collapsing them is on the list.

## License

MIT.
