// Compiled against vanilla Minecraft only. No loader APIs in here.
plugins {
    id("java-library")
    id("net.fabricmc.fabric-loom")
}

val minecraftVersion: String = providers.gradleProperty("minecraft_version").get()

java.toolchain.languageVersion = JavaLanguageVersion.of(25)

dependencies {
    minecraft("com.mojang:minecraft:$minecraftVersion")
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
