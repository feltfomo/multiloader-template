import mod.ModConfig

// Compiled against vanilla Minecraft only. No loader APIs in here.
plugins {
    id("java-library")
    id("net.fabricmc.fabric-loom")
}

// Minecraft + loader versions come from pkl/mod.pkl via buildSrc (one source).
val modConfig = ModConfig.load(rootDir.resolve("pkl/mod.pkl"))
val minecraftVersion: String    = modConfig.mcVersion
val fabricLoaderVersion: String = modConfig.fabricLoaderVersion

// Languages are opt-in (see pkl/mod.pkl). Java is always on; Kotlin and Scala
// join common/ on demand. The kotlin plugin is declared apply-false in the root
// build so every module shares one classloader with Loom; scala is a core
// Gradle plugin and needs no such ceremony.
if (modConfig.kotlin) pluginManager.apply("org.jetbrains.kotlin.jvm")
if (modConfig.scala) pluginManager.apply("scala")

java.toolchain.languageVersion = JavaLanguageVersion.of(25)

dependencies {
    minecraft("com.mojang:minecraft:$minecraftVersion")
    // No mappings line. MC 26.1 ships unobfuscated, so Loom remaps nothing and
    // rejects any mappings dependency, officialMojangMappings() included.

    // Compile-only: pulls Sponge Mixin onto common's classpath so mixins can be
    // authored here (in any JVM lang) without coupling common to a runtime loader.
    // Both Fabric and NeoForge supply Mixin at runtime, so this never ships.
    compileOnly("net.fabricmc:fabric-loader:$fabricLoaderVersion")

    // Scala 3 for common code + mixins, only when scala is enabled (pkl/mod.pkl).
    // The runtime is bundled into each loader jar downstream (fabric `include`,
    // neoforge `jarJar`); version comes from pkl.
    if (modConfig.scala) {
        implementation("org.scala-lang:scala3-library_3:${modConfig.scalaVersion}")
    }

    // Kotlin as an entry-point / common-logic language. Not for mixins — Kotlin's
    // compiled output (synthetic classes, null checks) fights Mixin's bytecode model.
    // The runtime is bundled per loader downstream the same way Scala is, but the
    // kotlin plugin (applied above only when enabled) already puts kotlin-stdlib
    // on this module's classpath, so there's nothing to declare here.
}

sourceSets {
    val main by getting
    create("client") {
        compileClasspath += main.compileClasspath + main.output
        runtimeClasspath += main.runtimeClasspath + main.output
    }
}

tasks.withType<JavaCompile>().configureEach {
    options.encoding = "UTF-8"
    options.release = 25
}
