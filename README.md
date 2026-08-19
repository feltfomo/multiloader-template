# multiloader-template

[![CI](https://github.com/feltfomo/multiloader-template/actions/workflows/ci.yml/badge.svg)](https://github.com/feltfomo/multiloader-template/actions/workflows/ci.yml)

A `cargo new` for Minecraft mods. One command scaffolds a project that builds for Fabric and NeoForge from a single codebase, with mixins, Pkl-generated configs, and JVM-language entrypoints already wired up.

The design is common-is-the-mod: you write everything in `common/` against vanilla Minecraft, and the loader folders are thin shims that hand off to it. No loader-specific APIs in your logic, and mixins for anything that has to touch the game.

## Create a new mod

Arguments are `<mod_id> <group> [display name]`. The id and each group segment must be lowercase `[a-z][a-z0-9_]*` (no dashes). All three methods below produce the same project.

### Nix run (recommended)

```bash
nix run github:feltfomo/multiloader-template#new -- coolmod com.example.coolmod 'Cool Mod'
```

Creates `./coolmod` in the current directory, rewrites every placeholder, and removes the scaffold script when it finishes. Run it from where you want the project to land (e.g. `~/Projects`), not from inside this repo. Nushell is bundled into the Nix app, so it doesn't need to be installed separately.

### Nix flake template

```bash
nix flake new -t github:feltfomo/multiloader-template ./coolmod
cd coolmod
nu scaffold.nu
```

### degit (no Nix)

```bash
npx degit feltfomo/multiloader-template/template coolmod
cd coolmod
nu scaffold.nu
```

The flake-template and degit paths need Nushell for the one-shot scaffolder. From a full clone you can run `nu new-mc-mod.nu coolmod com.example.coolmod 'Cool Mod'` from the repo root. `scaffold.nu` runs interactively when given no args, prompting for id, group, and name, and deletes itself when done.

## Build and run

Full per-project instructions live in `template/README.md`. Short version, from inside a generated project:

```bash
nix develop
./gradlew build
./gradlew :fabric:runClient
./gradlew :neoforge:runClient
```

The dev shell lives in the generated project, not in this repo root. Use `./gradlew`, not a system `gradle`: the wrapper is pinned to a version that runs on Java 25, and an older system gradle fails with a bare version-number error like `25.0.4`.

No Nix on the machine? Use `./mcw` in place of `./gradlew`. On first run it fetches a pinned Temurin 25 into `.jdk/` and then hands off to the wrapper, so `./mcw build` works from nothing but a clone.

## What's in the box

```
template/           the project that gets copied out
  pkl/mod.pkl       single source of mod identity + mixin list
  common/           your code, compiled against vanilla Minecraft
  fabric/           fabric entry shim
  neoforge/         neoforge entry shim
  flake.nix         dev shell: Java 25, Pkl, and the gradle wrapper
  scaffold.nu       placeholder rewriter, runs once then deletes itself
  mcw               no-Nix build wrapper: fetches JDK 25, runs the wrapper
new-mc-mod.nu       the generator the nix app runs
flake.nix           exposes the #new app and the flake template
.github/            ci that scaffolds a mod and builds both loaders
```

Pkl renders `fabric.mod.json`, the NeoForge `mods.toml`, and the mixin configs from `pkl/mod.pkl` at build time, so the loader manifests never drift from each other.

## Stack

Minecraft 26.1.2, Java 25, Gradle 9.5.1 (wrapper), Fabric Loom, NeoForge moddev, Pkl, Nushell. Kotlin and Scala are wired in as examples of mixed-language common code; both ride along in the built jar.
