import mod.ModConfig

plugins {
    id("java-library")
    id("net.neoforged.moddev")
}

// Minecraft + loader versions come from pkl/mod.pkl via buildSrc (one source).
// Scala + Kotlin toolchain versions still live in gradle.properties.
val modConfig = ModConfig.load(rootDir.resolve("pkl/mod.pkl"))
val neoVersion: String   = modConfig.neoVersion
val scalaVersion: String = providers.gradleProperty("scala_version").get()
val kotlinVersion: String = providers.gradleProperty("kotlin_version").get()

java.toolchain.languageVersion = JavaLanguageVersion.of(25)

val commonProject = project(":common")
val commonSourceSets = commonProject.extensions.getByType<SourceSetContainer>()

neoForge {
    version = neoVersion
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

    // common is Scala now, so its runtime must be present in dev and bundled
    // into the single neoforge jar (jarJar) for production.
    implementation("org.scala-lang:scala3-library_3:$scalaVersion")
    jarJar("org.scala-lang:scala3-library_3:$scalaVersion")

    // Kotlin runtime: same treatment so Kotlin common code runs in dev and ships.
    implementation("org.jetbrains.kotlin:kotlin-stdlib:$kotlinVersion")
    jarJar("org.jetbrains.kotlin:kotlin-stdlib:$kotlinVersion")
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
}

tasks.withType<JavaCompile>().configureEach {
    options.encoding = "UTF-8"
    options.release = 25
}
