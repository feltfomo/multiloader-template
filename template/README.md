# modid

A Minecraft mod that runs on Fabric and NeoForge from a single codebase. Built from feltfomo's multiloader template.

You write your code in `common/`, against vanilla Minecraft. The loader folders are thin shims that just hand off to common, so you rarely open them.

## Build

```bash
nix develop          # or install Java 25, Pkl 0.31+, Gradle 9.4+ yourself
./gradlew :fabric:build
```

Fabric works today. The NeoForge shim is in place and getting wired up.

## Make it yours

Everything that names the mod is in `pkl/mod.pkl` — id, name, group, version, authors. Change those, then rebuild. The build regenerates the loader manifests and mixin configs from that one file, so you never touch a `fabric.mod.json` directly. (If you want to see the generated output without a full build: `pkl eval -m build/generated pkl/mod.pkl`.)

## Mixins

Put your mixin class under `common/src/main/java/.../mixin/` (or `.../mixin/client/` for client-only), add its name to the mixin list in `pkl/mod.pkl`, and rebuild. One entry and every loader picks it up.

## What's where

```
pkl/mod.pkl   your mod's identity + mixin list
common/       your code, compiled against vanilla
fabric/       fabric entry shim
neoforge/     neoforge entry shim
```

Most of your time is spent in `common/`.
