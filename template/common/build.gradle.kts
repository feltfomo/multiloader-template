// Compiled against vanilla Minecraft only. No loader APIs in here.
plugins {
    id("java-library")
    id("scala")
    id("org.jetbrains.kotlin.jvm")
    id("net.fabricmc.fabric-loom")
}

val minecraftVersion: String     = providers.gradleProperty("minecraft_version").get()
val scalaVersion: String         = providers.gradleProperty("scala_version").get()
val kotlinVersion: String        = providers.gradleProperty("kotlin_version").get()
val fabricLoaderVersion: String  = providers.gradleProperty("fabric_loader_version").get()

java.toolchain.languageVersion = JavaLanguageVersion.of(25)

dependencies {
    minecraft("com.mojang:minecraft:$minecraftVersion")
    // No mappings line. MC 26.1 ships unobfuscated, so Loom remaps nothing and
    // rejects any mappings dependency, officialMojangMappings() included.

    // Compile-only: pulls Sponge Mixin onto common's classpath so mixins can be
    // authored here (in any JVM lang) without coupling common to a runtime loader.
    // Both Fabric and NeoForge supply Mixin at runtime, so this never ships.
    compileOnly("net.fabricmc:fabric-loader:$fabricLoaderVersion")

    // Scala 3 as a first-class language for common code + mixins.
    // Bundled into each loader jar downstream (fabric `include`, neoforge `jarJar`).
    implementation("org.scala-lang:scala3-library_3:$scalaVersion")

    // Kotlin as an entry-point / common-logic language. Not for mixins — Kotlin's
    // compiled output (synthetic classes, null checks) fights Mixin's bytecode model.
    // Bundled per loader downstream the same way Scala is.
    implementation("org.jetbrains.kotlin:kotlin-stdlib:$kotlinVersion")
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
