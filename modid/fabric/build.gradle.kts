// Fabric bootstrap — wires the common module into Fabric's loader.
plugins {
    id("java-library")
    id("org.jetbrains.kotlin.jvm")
    id("scala")
    id("net.fabricmc.fabric-loom")
}

val minecraftVersion: String    = providers.gradleProperty("minecraft_version").get()
val scalaVersion: String        = providers.gradleProperty("scala_version").get()
val slpFabricVersion: String    = providers.gradleProperty("slp_fabric_version").get()
val fabricLoaderVersion: String = providers.gradleProperty("fabric_loader_version").get()

java.toolchain.languageVersion = JavaLanguageVersion.of(25)

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_25)
    }
}

loom {
    splitEnvironmentSourceSets()
    mods {
        register("modid") {
            sourceSet(sourceSets.main.get())
            sourceSet(sourceSets.getByName("client"))
        }
    }
}

sourceSets.configureEach {
    kotlin.srcDir("src/$name/kotlin")
}

repositories {
    maven {
        name = "Kotori316"
        url = uri("https://maven.kotori316.com")
        content {
            includeGroup("com.kotori316")
            includeVersion("org.typelevel", "cats-core_3",   "2.13.0-kotori")
            includeVersion("org.typelevel", "cats-kernel_3", "2.13.0-kotori")
            includeVersion("org.typelevel", "cats-free_3",   "2.13.0-kotori")
        }
    }
}

val commonProject    = project(":common")
val commonSourceSets = commonProject.extensions.getByType<SourceSetContainer>()

dependencies {
    minecraft("com.mojang:minecraft:$minecraftVersion")
    implementation("net.fabricmc:fabric-loader:$fabricLoaderVersion")
    implementation("com.kotori316:scalable-cats-force-fabric:$slpFabricVersion:dev")
    implementation("org.scala-lang:scala3-library_3:$scalaVersion")
    implementation(commonProject)
    "clientImplementation"(commonSourceSets.getByName("client").output)
}

tasks.processResources {
    val props = mapOf(
        "version"               to version,
        "mod_id"                to providers.gradleProperty("mod_id").get(),
        "mod_name"              to providers.gradleProperty("mod_name").get(),
        "mod_description"       to providers.gradleProperty("mod_description").get(),
        "mod_license"           to providers.gradleProperty("mod_license").get(),
        "mod_authors"           to providers.gradleProperty("mod_authors").get(),
        "minecraft_version"     to minecraftVersion,
        "fabric_loader_version" to fabricLoaderVersion,
        "fabric_kotlin_version" to providers.gradleProperty("fabric_kotlin_version").get(),
    )
    inputs.properties(props)
    filesMatching("fabric.mod.json") { expand(props) }
}

tasks.withType<JavaCompile>().configureEach {
    options.encoding = "UTF-8"
    options.release  = 25
}
