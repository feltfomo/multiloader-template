import mod.ModConfig
import org.jetbrains.kotlin.gradle.plugin.getKotlinPluginVersion

plugins {
    id("java-library")
    id("net.neoforged.moddev")
}

// Minecraft + loader versions come from pkl/mod.pkl via buildSrc (one source).
val modConfig = ModConfig.load(rootDir.resolve("pkl/mod.pkl"))
val neoVersion: String = modConfig.neoVersion

// When Kotlin is enabled, apply the plugin here too so the jar-in-jar coordinate
// below can read the version straight from the plugin (one source, no sync).
if (modConfig.kotlin) pluginManager.apply("org.jetbrains.kotlin.jvm")

java.toolchain.languageVersion = JavaLanguageVersion.of(25)

val commonProject = project(":common")
val commonSourceSets = commonProject.extensions.getByType<SourceSetContainer>()

neoForge {
    version = neoVersion
    // Generated from pkl/mod.pkl's accessEntries; read from the stable dir the
    // root build writes during configuration (clean-build safe).
    if (modConfig.hasAccessWideners) {
        accessTransformers.from(rootProject.file(".pkl-generated/accesstransformer.cfg"))
    }
    runs {
        create("client") { client() }
        create("server") {
            server()
            programArguments.add("--nogui")
        }
    }
    mods {
        create("modid") {
            sourceSet(sourceSets.main.get())
            sourceSet(commonSourceSets.getByName("main"))
            sourceSet(commonSourceSets.getByName("client"))
        }
    }
}

dependencies {
    compileOnly(commonSourceSets.getByName("main").output)
    compileOnly(commonSourceSets.getByName("client").output)

    // Each language runtime must be present in dev and bundled into the single
    // neoforge jar (jarJar) for production -- but only when that language is on.
    // Scala version from pkl; Kotlin version from the applied plugin.
    if (modConfig.scala) {
        implementation("org.scala-lang:scala3-library_3:${modConfig.scalaVersion}")
        jarJar("org.scala-lang:scala3-library_3:${modConfig.scalaVersion}")
    }
    if (modConfig.kotlin) {
        val kotlinStdlib = "org.jetbrains.kotlin:kotlin-stdlib:${getKotlinPluginVersion()}"
        implementation(kotlinStdlib)
        jarJar(kotlinStdlib)
    }
}

// NeoForge ships a single jar, so common has to ride inside it.
tasks.named<Jar>("jar") {
    from(commonSourceSets.getByName("main").output)
    from(commonSourceSets.getByName("client").output)
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
}

val generated = rootProject.layout.buildDirectory.dir("generated")
tasks.named<ProcessResources>("processResources") {
    dependsOn(":generatePklConfigs")
    from(generated.map { it.dir("neoforge") }) { into("META-INF") }
    from(generated.map { it.dir("common") })
    // Production NeoForge reads META-INF/accesstransformer.cfg from the jar.
    if (modConfig.hasAccessWideners) {
        from(rootProject.file(".pkl-generated/accesstransformer.cfg")) { into("META-INF") }
        duplicatesStrategy = DuplicatesStrategy.EXCLUDE
    }
}

tasks.withType<JavaCompile>().configureEach {
    options.encoding = "UTF-8"
    options.release = 25
}
