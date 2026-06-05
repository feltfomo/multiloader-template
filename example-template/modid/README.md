# Modid

A Minecraft mod.

## Stack

- **Minecraft 26.1.2** — unobfuscated, Mojang mappings
- **Java 25** — required by MC 26.1+
- **Gradle 9.4** / Kotlin DSL throughout
- **Languages**: Java → Kotlin → Scala (compiled in this order; Scala can call everything)
- **Scala entrypoints** via [SLP (Kotori316)](https://github.com/Kotori316/SLP) on both loaders

## Structure

```
.
├── common/          # All real mod code — no loader deps
│   └── src/
│       ├── main/    # Shared, server-safe code
│       └── client/  # Client-only code
├── fabric/          # Fabric bootstrap shim
└── neoforge/        # NeoForge bootstrap shim
```

## Running

```bash
./gradlew :fabric:runClient
./gradlew :neoforge:runClient
```

## Language rules

- **Java** — mixins, low-level bindings
- **Kotlin** — primary application language
- **Scala** — entrypoints, data pipelines, transformation layers

Scala compiles last so it can freely call Java and Kotlin. Don't call Scala from Java or Kotlin directly.
