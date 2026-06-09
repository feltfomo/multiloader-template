# Multiloader template — design & maintainer notes

Read this first. It's the contract for how the template is built and why.

## Goal
Setting up a multiloader Minecraft mod should feel like `cargo new`. You write your mod once in `common`, in whatever JVM language you want, and never hand-edit loader manifests or touch loader-specific wiring. The loaders (Fabric, NeoForge, Quilt) are thin generated shims around your code.

## Core rules
- **Common is the mod.** All logic lives in `common`, built against vanilla only. No loader APIs in `common`.
- **No loader-specific API in your code.** Behavior that must differ per loader hides behind a small loader-agnostic interface in `common`, with per-loader implementations in the shim modules. The event bus lib will be the first of these.
- **Mixins are the cross-loader substrate.** All three loaders run SpongePowered Mixin and the config format is identical. Mixin classes and the `.mixins.json` configs live once in `common`; each loader manifest just references them. Adding a mixin means adding one class name to the Pkl source, not editing three manifests.
- **One source of truth for config.** A single Pkl file (`pkl/mod.pkl`) generates `fabric.mod.json`, `quilt.mod.json`, `neoforge.mods.toml`, and the mixin configs. Generated files go to `build/` and are not committed.
- **Entrypoint is always a Java shim.** Java's language adapter ships with every loader, so the loader-facing entrypoint is a tiny Java class that calls your `init()`. This drops the SLP dependency the old template used. Your actual logic can live in any language; the shim just calls into it.

## Languages
- First-class (statically compiled, slot straight into `common`): Java, Kotlin, Scala, Groovy (`@CompileStatic`).
- Logic tier (dynamic, needs its runtime bundled plus a bootstrap from the shim): Clojure.
- Not scaffolded, advanced/bring-your-own: JRuby, Jython.
- Compile order is a DAG: Java then Kotlin then Scala. Whoever compiles last sees the others, so cross-language visibility is one-directional. This is about compile order, not about which language is the entrypoint.

## Loaders
Fabric + NeoForge + Quilt all get real modules. Quilt is a user runtime choice; if it lags a loader update, that is on whoever opts into Quilt.

## Toolchain
- Minecraft 26.1.x is unobfuscated (Mojang dropped obfuscation; releases before 26.1 were obfuscated). Remapping is on the way out, but the build tools still carry remap machinery as a near no-op, so don't depend on it being fully gone yet.
- Java 25, Gradle 9.4. The flake devshell pins Java + Gradle + Pkl so `nix develop` gives you the whole environment.

## Delivery
- Primary: Nix flake template + devshell.
- Fallback for non-Nix users: degit / git template, with a one-shot init step for name substitution.

## Working contract (generalized from the notion-sync maintainer guide)
- Lean dependencies. Each language adapter and tool has to earn its place. Pkl earns it on validation; a Clojure-on-NeoForge adapter does not for v1.
- Fail loud at input boundaries with clear messages. The generator validates ids and groups up front.
- Ship a smoke test: generate, then `gradle build` must actually run.
- Make the first version fast, not just working — get the shape right before filling it in.
- Prose and comments: blunt, concrete, contractions, no filler.

## Status
- Done: Pkl single-source schema + renderers (validated against golden output), flake devshell, this doc.
- Next: port the loader modules to Java-shim entrypoints, add the Quilt module, wire Gradle to consume the generated configs from `build/`, scaffold the language source sets, and replace the bash generator with the flake template + degit path.
