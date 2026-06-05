// NeoForge bootstrap — wires the common module into NeoForge's loader.
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

sourceSets {
    val main by getting
    create("client") {
        compileClasspath += main.compileClasspath + main.output
        runtimeClasspath += main.runtimeClasspath + main.output
    }
}

sourceSets.configureEach {
    kotlin.srcDir("src/$name/kotlin")
}

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

val commonProject    = project(":common")
val commonSourceSets = commonProject.extensions.getByType<SourceSetContainer>()

dependencies {
    implementation("com.kotori316:scalablecatsforce-neoforge:$slpNeoVersion") {
        isTransitive = false
    }
    implementation("org.scala-lang:scala3-library_3:$scalaVersion")
    compileOnly(commonProject)
    "clientCompileOnly"(commonSourceSets.getByName("client").output)
}

tasks.named<ProcessResources>("processResources") {
    from(sourceSets.getByName("client").resources)

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
