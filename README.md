# multiloader-template

[![CI](https://github.com/feltfomo/multiloader-template/actions/workflows/ci.yml/badge.svg)](https://github.com/feltfomo/multiloader-template/actions/workflows/ci.yml)

A `cargo new`-style generator for Minecraft mods. One command produces a ready-to-build Fabric and NeoForge project from a shared codebase.

The generated project already knows its language, physical side, loader entrypoints, mixins, manifests, datagen setup, and runtime dependencies. Start in `common/` and write the mod.

## Create a mod

Arguments are `<mod_id> <group> [display name]`. The id and every group segment must be lowercase `[a-z][a-z0-9_]*`.

```bash
nix run github:feltfomo/multiloader-template#new -- \
  coolmod \
  com.example.coolmod \
  'Cool Mod'
```

The default is a Java mod for both client and server with datagen enabled. The author defaults to `git config user.name`; pass `--author` when Git has no configured name.

### Standalone release script

Nushell users can download one pinned bootstrap without cloning the repository or installing Nix:

```bash
curl --fail --location --remote-name \
  https://github.com/feltfomo/multiloader-template/releases/download/v1.2.0/create-mc-mod.nu

nu create-mc-mod.nu \
  coolmod com.example.coolmod 'Cool Mod' \
  --language scala --side client
```

The release also includes `create-mc-mod.nu.sha256`. The bootstrap downloads the matching tagged template into a temporary directory, generates the project in the current directory, and removes the temporary copy.

### Choose an archetype

```bash
# scala client mod
nix run github:feltfomo/multiloader-template#new -- \
  coolmod com.example.coolmod 'Cool Mod' \
  --language scala --side client

# kotlin dedicated-server mod without the sample datagen setup
nix run github:feltfomo/multiloader-template#new -- \
  coolmod com.example.coolmod 'Cool Mod' \
  --language kotlin --side server --no-datagen
```

| Option | Values | Default |
| --- | --- | --- |
| `--language` | `java`, `kotlin`, `scala` | `java` |
| `--side` | `both`, `client`, `server` | `both` |
| `--no-datagen` | removes the bundled server-data example | off |
| `--version` | initial mod version | `1.0.0` |
| `--author` | manifest author | Git user name |
| `--license` | project license identifier | `MIT` |
| `--description` | manifest description | `A Minecraft mod.` |

A client-only project defaults datagen off because the bundled providers generate server data. The older `--kotlin` and `--scala` shortcuts remain accepted, but `--language` is the clearer interface.

The Nix app bundles Nushell and the GNU tools used by the generator. Run it from the directory where the project should be created.

### Copy the template first

```bash
nix flake new -t github:feltfomo/multiloader-template ./coolmod
cd coolmod
nu scaffold.nu
```

The same interactive scaffolder works after a direct template copy:

```bash
npx degit feltfomo/multiloader-template/template coolmod
cd coolmod
nu scaffold.nu
```

These two paths need Nushell installed because they call `scaffold.nu` directly.

## What gets generated

The scaffolder removes every starter that does not belong to the chosen archetype:

- client projects keep only client initialization and client mixins
- server projects remove client entrypoints, client sources, and client mixins
- both-side projects keep shared and client initialization
- only the selected JVM-language starter and runtime remain
- datagen sources and tasks disappear when datagen is disabled

Loader entrypoints stay as tiny Java shims. The code to edit lives in the selected starter under `common/`. Mixins remain Java because their bytecode shape needs to stay predictable.

## Configuration

`template/pkl/mod.pkl` is the small public project file. It contains identity, archetype, versions, mixin names, and access entries in one readable place.

`template/pkl/render.pkl` owns validation and rendering for:

- `fabric.mod.json`
- `neoforge.mods.toml`
- common and client mixin configs
- Fabric access wideners
- NeoForge access transformers

Generated projects should edit `pkl/mod.pkl` and leave `pkl/render.pkl` alone.

## Build and run

From a generated project:

```bash
./mcw build
./mcw :fabric:runClient
./mcw :neoforge:runClient
```

`mcw` finds JDK 25 or downloads a private Temurin 25 into `.jdk/`, then runs the pinned Gradle wrapper. With Nix or an existing JDK 25, use `nix develop` and `./gradlew` instead.

For a server archetype, use the corresponding `runServer` tasks.

### Nix development environment

Generated projects include a flake-parts development shell with JDK 25, Linux LWJGL runtime libraries, OpenGL, Vulkan, X11, Wayland, OpenAL, and diagnostic `vulkaninfo` support. Host GPU drivers still come from the operating system.

```bash
nix develop
nix fmt
nix flake check
```

`dev.nix` is the intended customization point for adding or removing packages. `formatter.nix` configures treefmt, nixfmt, and statix.

## Repository layout

```text
template/             project copied by the generator
  pkl/mod.pkl         public project configuration
  pkl/render.pkl      schema and loader-format renderers
  common/             selected starter, shared code, and mixins
  fabric/             Fabric loader shims and optional datagen
  neoforge/           NeoForge loader shims and optional datagen
  scaffold.nu         one-shot archetype scaffolder
  dev.nix             customizable development shell
  formatter.nix       treefmt configuration
  mcw                 no-Nix JDK and Gradle bootstrap
new-mc-mod.nu         internal copy-and-scaffold implementation
create-mc-mod.nu      standalone release bootstrap
flake.nix             exposes the app and flake template
.github/workflows/    build matrix and tag release automation
```

CI builds Java/both, Kotlin/server, and Scala/client generated projects so the choices stay real rather than decorative.

## Stack

Minecraft 26.1.2, Java 25, Gradle 9.5.1, Fabric Loom, NeoForge ModDev, Pkl, and Nushell. Kotlin and Scala runtimes are bundled only when selected.
