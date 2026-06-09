plugins {
    id("java-library")
    id("net.neoforged.moddev")
}

val neoVersion: String = providers.gradleProperty("neo_version").get()

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
