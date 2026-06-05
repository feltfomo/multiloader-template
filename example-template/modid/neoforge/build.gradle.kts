// NeoForge bootstrap. Wires the common module into NeoForge's loader.
plugins {
    id("java-library")
    id("org.jetbrains.kotlin.jvm")
    id("scala")
    id("net.neoforged.moddev")
}

val minecraftVersion: String = providers.gradleProperty("minecraft_version").get()
val neoVersion: String       = providers.gradleProperty("neo_version").get()
val scalaVersion: String     = providers.gradleProperty("scala_version").get()
val slpNeoVersion: String    = providers.gradleProperty("slp_neoforge_version").get()

java.toolchain.languageVersion = JavaLanguageVersion.of(25)

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_25)
    }
}

sourceSets.configureEach {
    kotlin.srcDir("src/$name/kotlin")
}

// common's compiled classes, without loom's remapped deps
val commonProject    = project(":common")
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
            // neoforge ships one jar, so common rides inside this mod
            sourceSet(sourceSets.main.get())
            sourceSet(commonSourceSets.getByName("main"))
            sourceSet(commonSourceSets.getByName("client"))
        }
    }
}

repositories {
    maven {
        name = "Kotori316"
        url = uri("https://maven.kotori316.com")
        content { includeGroup("com.kotori316") }
    }
}

dependencies {
    implementation("com.kotori316:scalablecatsforce-neoforge:$slpNeoVersion") {
        isTransitive = false
    }
    // slp provides the scala library at runtime
    compileOnly("org.scala-lang:scala3-library_3:$scalaVersion")
    // compile against common, runtime comes from the mods block
    compileOnly(commonSourceSets.getByName("main").output)
    compileOnly(commonSourceSets.getByName("client").output)
}

// fold common into the built jar
tasks.named<Jar>("jar") {
    from(commonSourceSets.getByName("main").output)
    from(commonSourceSets.getByName("client").output)
    duplicatesStrategy = DuplicatesStrategy.EXCLUDE
}

tasks.named<ProcessResources>("processResources") {
    val props = mapOf(
        "mod_id"                  to providers.gradleProperty("mod_id").get(),
        "mod_name"                to providers.gradleProperty("mod_name").get(),
        "mod_description"         to providers.gradleProperty("mod_description").get(),
        "mod_license"             to providers.gradleProperty("mod_license").get(),
        "mod_authors"             to providers.gradleProperty("mod_authors").get(),
        "mod_version"             to version.toString(),
        "neo_version"             to neoVersion,
        "minecraft_version"       to minecraftVersion,
        "minecraft_version_range" to providers.gradleProperty("minecraft_version_range").get(),
        "neo_version_range"       to providers.gradleProperty("neo_version_range").get(),
    )
    inputs.properties(props)
    filesMatching("META-INF/neoforge.mods.toml") { expand(props) }
}

tasks.withType<JavaCompile>().configureEach {
    options.encoding = "UTF-8"
    options.release  = 25
}
